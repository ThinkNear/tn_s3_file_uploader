require 'rubygems'
require 'aws-sdk'
require 'honeybadger'
require 'tn_s3_file_uploader/log_uploader'

module TnS3FileUploader
  class Runner

    def initialize(options)
      @options = options
      @error_report_manager = ErrorReportManager.instance
    end

    def run
      add_log_error_reporter
      add_honeybadger
      puts "Running TnS3FileUploader..." if @options[:verbose]

      upload
    rescue Exception => e
      @error_report_manager.report_error(e, { :options => @options } )
    end

    private

    def upload
      if @options[:verbose]
        puts "Using:"
        puts "log file pattern = #{ @options[:input_file_pattern] }"
        puts "s3 dest folder = #{ @options[:s3_output_pattern] }"
        puts "file timestamp resolution = #{ options[:file_timestamp_resolution] }"
      end

      s3_client = create_s3_client
      s3 = S3.new(s3_client)

      log_uploader = LogUploader.new(s3)
      log_uploader.upload_log_files(@options)
    end

    def create_s3_client
      if @options[:aws_access_key_id].nil? && @options[:aws_secret_access_key].nil?
        AWS::S3.new
      else
        AWS::S3.new(
            :access_key_id => @options[:aws_access_key_id],
            :secret_access_key => @options[:aws_secret_access_key]
        )
      end
    end

    def add_log_error_reporter
      @error_report_manager.register_error_reporter(LogErrorReporter.new(STDOUT))
    end

    def add_honeybadger
      unless @options[:honeybadger_api_key].nil?
        honeybadger_error_reporter = HoneybadgerErrorReporter.new(@options[:honeybadger_api_key])
        @error_report_manager.register_error_reporter(honeybadger_error_reporter)
      end
    end

  end
end
