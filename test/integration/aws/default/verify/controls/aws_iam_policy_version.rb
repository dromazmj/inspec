fixtures = {}
[
  'iam_policy_for_policy_version',
  'iam_policy_for_policy_version_2',
  'bucket_for_policy_version_1',
  'bucket_for_policy_version_2',
  'bucket_for_policy_version_3',
  'iam_user_for_policy_version_1'
].each do |fixture_name|
  fixtures[fixture_name] = attribute(
    fixture_name,
    default: "default.#{fixture_name}",
    description: 'See ../build/iam.tf',
  )
end

control "aws_iam_policy_version recall" do
  describe aws_iam_policy_version(policy_arn: fixtures['iam_policy_for_policy_version'], policy_version: 'v1') do
    it { should exist }
  end

  describe aws_iam_policy_version(policy_arn: "NonExistentPolicy", policy_version: 'v1') do
    it { should_not exist }
  end
end

control "aws_iam_policy_version matchers" do
  # Test a basic statement
  describe aws_iam_policy_version(policy_arn: fixtures['iam_policy_for_policy_version_1'], policy_version: 'v1') do
    # Test a policy with all fields inputed
    it { should have_statement({
      Action: 's3:ListAllMyBuckets', 
      Resource: fixtures['bucket_for_policy_version_1'], 
      Effect: 'Allow',
    })}
  end
  
  # Test a statement with all fields inputed
  describe aws_iam_policy_version(policy_arn: fixtures['iam_policy_for_policy_version_2'], policy_version: 'v1') do
    it { should have_statement({
      Sid: 1,
      Effect: 'Allow',
      Action: ['s3:ListAllMyBuckets', 's3:GetBucketLocation'], 
      Not_Action: 'ec2:RunInstances',
      Resource: [fixtures['bucket_for_policy_version_1'], fixtures['bucket_for_policy_version_2']],
      Not_Resource: fixtures['bucket_for_policy_version_3'], 
      Principal: fixtures['iam_user_for_policy_version_1'],
      Not_Principal: "ec2.amazonaws.com",
      Condition:{
        StringLike: {"s3:acl"=>"public-read"}
      },
    })}
  end
end