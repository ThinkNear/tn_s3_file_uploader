require 'optparse'
require 'tn_s3_file_uploader/version'

module TnS3FileUploader

  class CliParser

    # Parses the CLI parameters and returns them in a hash
    # Parameters 'host-unique-id', 'log-file-pattern', 's3-dest-folder' and 'partition-pattern' are mandatory and
    # a missing argument exception will be raised if any of them is not provided
    def parse_cmd_line(args)
      options = {}
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: tn_s3_file_uploader.rb [options]"

        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-s", "--input-file-pattern INPUT_FILE_PATTERN", "The file pattern to match the source log file") do |file_pattern|
          options[:input_file_pattern] = file_pattern
        end

        opts.on("-o", "--s3-output-pattern S3_OUTPUT_PATTERN", "The S3 destination pattern name."\
            "It accepts macros for building the resulting filename and folder structure. See documentation for details") do |s3_output_pattern|
          options[:s3_output_pattern] = s3_output_pattern
        end

        options[:delete_log_files_flag] = false
        opts.on("-d", "--delete-log-files [DELETE_LOG_FILES]", "The flag for deleting log files"\
            "It is an optional parameter, default is false, decides if log files are deleted after successful upload") do |delete_log_files_flag|
          options[:delete_log_files_flag] = delete_log_files_flag
        end

        options[:fixed_time] = ""
        opts.on("-t", "--fixed-time [FIXED_TIME]", "The time which will be added to generated log name"\
            "It is an optional parameter. Use this argument to override time used to specify the resolution for the timestamp, if this option is not provided the time to use will be script run time.") do |fixed_time|
          options[:fixed_time] = fixed_time
        end

        options[:file_timestamp_resolution] = 300
        opts.on("--file-timestamp-resolution RES", Integer, "The resolution of the destination filename in seconds (positive non-zero integer)") do |file_timestamp_resolution|
          if valid_seconds?(file_timestamp_resolution)
            options[:file_timestamp_resolution] = file_timestamp_resolution
          else
            puts "Warning: negative seconds value given: #{file_timestamp_resolution}, defaulting to 300 (5 minutes)"
          end
        end

        opts.on("--honeybadger-api-key API-KEY", "API key for optional honeybadger error reporting support") do |honeybadger_api_key|
          options[:honeybadger_api_key] = honeybadger_api_key
        end

        opts.on("--aws-access-key-id AWS-ACCESS-KEY-ID", "Provide the AWS access key id.") do |aws_access_key_id|
          options[:aws_access_key_id] = aws_access_key_id
        end

        opts.on("--aws-secret-access-key AWS-SECRET-ACCESS-KEY", "Provide the AWS secret access key") do |aws_secret_access_key|
          options[:aws_secret_access_key] = aws_secret_access_key
        end

        options[:use_ec2_metadata_flag] = true
        opts.on("--use-ec2-metadata [USE_EC2_METADATA]", "The flag for using the ec2 instance metadata endpoint to lookup the local IP."\
            "It is an optional parameter, default is true.") do |use_ec2_metadata|
          options[:use_ec2_metadata_flag] = use_ec2_metadata
        end

        opts.on("-v", "--verbose", "Display verbose output") do |v|
          options[:verbose] = !v.nil?
        end

        opts.separator ""

        opts.on_tail("--version", "Display version number") do
          puts TnS3FileUploader::VERSION
          exit!
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit!
        end
      end

      opts.parse! args

      check_mandatory options

      options
    end

    private

    def check_mandatory(options)
      mandatory_arguments = [:input_file_pattern, :s3_output_pattern]

      missing_arguments = []
      mandatory_arguments.each do |arg|
        missing_arguments << arg.to_s.gsub!('_', '-') if options[arg].nil?
      end

      unless missing_arguments.empty?
        raise OptionParser::MissingArgument,
              "The following mandatory options are missing: #{ missing_arguments.join(', ') }"
      end
    end

    def valid_seconds?(seconds)
      seconds > 0
    end

  end

end