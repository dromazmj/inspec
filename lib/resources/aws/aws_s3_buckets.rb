# author: Matthew Dromazos
# author: Sam Cornwell
class AwsS3Buckets < Inspec.resource(1)
  name 'aws_s3_buckets'
  desc 'Verifies settings for AWS S3 Buckets in bulk'
  example "
    describe aws_s3_bucket do
      its('Bucket_names') { should eq ['my_bucket'] }
    end
  "
  supports platform: 'aws'

  include AwsPluralResourceMixin

  # Underlying FilterTable implementation.
  filter = FilterTable.create
  filter.add_accessor(:where)
        .add_accessor(:entries)
        .add(:exists?) { |x| !x.entries.empty? }
        .add(:bucket_names, field: :name)
        .add(:creation_dates, field: :creation_date)
  filter.connect(self, :table)

  def to_s
    'S3 Buckets'
  end

  def validate_params(resource_params)
    unless resource_params.empty?
      raise ArgumentError, 'aws_s3_buckets does not accept resource parameters.'
    end
    resource_params
  end

  private

  def fetch_from_api
    backend = BackendFactory.create(inspec_runner)
    @table = backend.list_buckets.buckets.map(&:to_h)
  end

  class Backend
    class AwsClientApi < AwsBackendBase
      BackendFactory.set_default_backend self
      self.aws_client_class = Aws::S3::Client

      def list_buckets
        aws_service_client.list_buckets
      end
    end
  end
end
