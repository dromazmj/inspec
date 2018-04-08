class AwsIamPolicyVersion < Inspec.resource(1)
  name 'aws_iam_policy_version'
  desc 'Verifies settings for individual AWS IAM Policy Version'
  example '
    # Test a policy with all fields inputed
    it { should have_statement({
      Action: "s3:ListAllMyBuckets", 
      Resource: "arn:aws:s3:::myBucket", 
      Effect: "Allow",
    })}
  '
  supports platform: 'aws'

  include AwsSingularResourceMixin 

  def to_s
    "Policy #{@policy_name}, Policy Version #{@policy_version}"
  end

  def has_statement(raw_criteria = {})
    recognized_criteria = statement_check_criteria(raw_criteria)
    recognized_criteria[:Sid] = "" if recognized_criteria[:Sid].nil?
    recognized_criteria[:Effect] = "Allow" if recognized_criteria[:Effect].nil?
    puts @document["Statement"].select { |statement| compare_statements(recognized_criteria.to_json, statement.to_json) }
    !@document["Statement"].select { |statement| compare_statements(recognized_criteria.to_json, statement.to_json) }.nil?
  end
  alias have_statement? has_statement
  alias has_statement? has_statement

  private
  
  def compare_statements(expected_statement, actual_statement)
    expected_statement["Effect"] == actual_statement["Effect"] &&
    expected_statement["Sid"] == actual_statement["Sid"] &&
    expected_statement["Resource"] == actual_statement["Resource"] &&
    expected_statement["Not_Resource"] == actual_statement["Not_Resource"] &&
    expected_statement["Action"] == actual_statement["Action"] &&
    expected_statement["Not_Action"] == actual_statement["Not_Action"] &&
    expected_statement["Principle"] == actual_statement["Principle"] &&
    expected_statement["Not_Principle"] == actual_statement["Not_Principle"] &&
    expected_statement["Condition"] == actual_statement["Condition"]
  end
  
  def statement_check_criteria(raw_criteria)
    allowed_criteria = [
      :Effect,
      :Resource,
      :Not_Resource,
      :Action,
      :Not_Action,
      :Principle,
      :Not_Principle,
      :Condition,
      :Sid,
    ]
    
    recognized_criteria = {}
    allowed_criteria.each do |expected_criterion|
      if raw_criteria.key?(expected_criterion)
        recognized_criteria[expected_criterion] = raw_criteria.delete(expected_criterion)
      end
    end

    # Any leftovers are unwelcome
    unless raw_criteria.empty?
      raise ArgumentError, "Unrecognized IAM Policy Version 'statement' criteria '#{raw_criteria.keys.join(',')}'. Expected criteria: #{allowed_criteria.join(', ')}"
    end

    recognized_criteria
  end

  def validate_params(raw_params)
    validated_params = check_resource_param_names(
      raw_params: raw_params,
      allowed_params: [:policy_arn, :policy_version],
    )
    
    if validated_params.key?(:polic_name).nil?
      raise ArgumentError, "You must provide the parameter 'policy_arn' to aws_iam_policy_version."
    end
    
    if validated_params.key?(:policy_version).nil?
      raise ArgumentError, "You must provide the parameter 'policy_version' to aws_iam_policy_version."
    end

    validated_params
  end

  def fetch_from_api
    backend = BackendFactory.create(inspec_runner)
    catch_aws_errors do
      policy_data = backend.get_policy_version({policy_arn: @policy_arn, version_id: @policy_version})
    end
    @exists = !policy_data.nil?

    return unless @exists
    @document = JSON.parse(CGI.unescape(policy_data.policy_version.document))
  end

  class Backend
    class AwsClientApi < AwsBackendBase
      BackendFactory.set_default_backend(self)
      self.aws_client_class = Aws::IAM::Client

      def get_policy_version(criteria)
        aws_service_client.get_policy_version(criteria)
      end
    end
  end
end
