require 'rubygems'
gem 'aws-sdk'
require 'aws-sdk'
require 'honeybadger'
require 'tn_s3_file_uploader/file_path_generator'
module TnS3FileUploader

  class S3

    MAX_RETRIES = 3

    def initialize(s3_client)
      @s3_client = s3_client
    end

    # File must be fully qualified
    # bucket is just string name, no slashes
    # dest_path is fully qualified path to file on S3 including folders - NO leading or trailing slashes or
    # it won't work!
    def upload_file(file, bucket, dest_path)
      raise ArgumentError, "file cannot be nil" if file == nil
      raise ArgumentError, "bucket cannot be nil" if bucket == nil
      raise ArgumentError, "dest_path cannot be nil" if dest_path == nil

      file_path = Pathname.new(file)
      raise ArgumentError, "#{file} is not a valid file" unless file_path.exist? && file_path.file?
      begin
      upload(bucket, dest_path, file)
      rescue StandardError, Timeout::Error => e
        raise e
      end
    end

    private
    def upload(bucket, dest_full_path, file, retry_count = 0)
      begin
        s3_bucket = @s3_client.buckets[bucket]
        s3_file_path = s3_bucket.objects[dest_full_path]

        puts "Uploading file #{file} to S3 bucket #{bucket} and path #{dest_full_path}"

        s3_file_path.write(File.open(file, 'rb'))
      rescue StandardError, Timeout::Error => e
        if retry_count < MAX_RETRIES
          #This fixes a bug where the credentials may have rotated on the EC2 instance but the old values
          #are still cached
          sleep 10
          @s3_client.config.credential_provider.refresh
          upload(bucket, dest_full_path, file, retry_count + 1)
        else
          raise e
        end
      end
    end
  end

end
