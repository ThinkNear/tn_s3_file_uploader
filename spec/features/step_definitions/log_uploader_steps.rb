require 'aws-sdk'
require 'tn_s3_file_uploader/log_uploader'
require 'tn_s3_file_uploader/s3'
require 'tn_s3_file_uploader/file_path_generator'
require 'tn_s3_file_uploader/log'


Before do
  @ip_address = '10-0-0-1'
  TnS3FileUploader::FilePathGenerator.any_instance.stub(:local_ip).and_return('10.0.0.1')
  @s3_client = AWS::S3.new(
      :access_key_id =>ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_KEY'],
      :s3_endpoint => 'localhost', # This should match Rakefile's run_fake_s3 task
      :s3_port => 4515, # This should match Rakefile's run_fake_s3 task
      :s3_force_path_style => true,
      :use_ssl => false)
  @s3 = TnS3FileUploader::S3.new(@s3_client)
  @log_uploader = TnS3FileUploader::LogUploader.new(@s3)
end

When(/^the log rotation script runs for input file pattern "([^"]*)" and S3 output pattern "([^"]*)"$/) do | input_file_pattern, s3_output_pattern |
  hash_params = {
      :input_file_pattern => input_file_pattern,
      :s3_output_pattern => s3_output_pattern,
      :file_timestamp_resolution => 300 # five minutes
  }
  @log_uploader.upload_log_files(hash_params)
end