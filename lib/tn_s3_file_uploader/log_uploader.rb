require 'rubygems'
require 'tn_s3_file_uploader/s3'
require 'tn_s3_file_uploader/file_path_generator'

module TnS3FileUploader

  class LogUploader

    # Initialisation block
    # Params:
    # ::s3:: - S3 wrapper
    def initialize(s3)
      raise ArgumentError, "s3 client cannot be nil" if s3 == nil
      @s3 = s3
    end

    # Uploads all (log) files that options[:input_file_pattern] matches to an S3 location
    # based on the value of options[:s3_output_pattern]
    # options[:input_file_pattern] should match at least one local file
    # options[:s3_output_pattern] should contain the bucket, folder and destination filename
    def upload_log_files(options)
      raise ArgumentError, 's3_output_pattern cannot be empty' if blank?(options[:s3_output_pattern])
      bucket = check_bucket_dest_path(options[:s3_output_pattern])
      log_files = check_log_files(options)

      file_path_generator = FilePathGenerator.new(options)

      log_files.each do |log_file|
        if options[:fixed_time].nil? || options[:fixed_time].empty?
          time = last_modified_time(log_file)
        else
          time = DateTime.strptime(options[:fixed_time], '%Y-%m-%d_%H:%M:%S').to_time
        end
        destination_full_path = file_path_generator.dest_full_path_for(time, log_file)

        Log.log "Found log file #{ log_file }, formatting file name for upload to S3 bucket #{ bucket } into folder #{ destination_full_path }"

        # Note no leading or trailing slashes - this will break the upload to S3 (see our s3.rb)
        begin
          @s3.upload_file(log_file, bucket, destination_full_path)
          if options[:delete_log_files_flag]
            delete_file(log_file)
          end
        rescue StandardError, Timeout::Error => e
          raise e
        end
      end

    end

    private
    def check_log_files(options)
      log_file_pattern = options[:input_file_pattern]

      raise ArgumentError, 'log file pattern cannot be nil' if log_file_pattern == nil

      last_folder_separator = log_file_pattern.rindex('.')
      raise ArgumentError, "#{ log_file_pattern } is not a valid path. It lacks a file extension." if last_folder_separator == nil

      files = Dir[log_file_pattern].entries
      if files.empty?
        if options[:verbose]
          options[:context] ||= {}
          disk_free_result = %x[df -h].split("\n")
          options[:context][:df] = disk_free_result
          logs_dir = %x[ls -l /media/ephemeral0/logs].split("\n")
          options[:context][:logs_dir] = logs_dir
          symlink_check = %x[ls -l /usr/share/tomcat7/].split("\n")
          options[:context][:symlink_check] = symlink_check
        end
        raise ArgumentError, "#{ log_file_pattern } did not match any files."
      end

      files
    end

    def check_bucket_dest_path(bucket_dest_path)
      path_components = bucket_dest_path.split('/')
      raise ArgumentError, "Bucket destination folder #{ bucket_dest_path } must have at least two path components, e.g. my/path." unless path_components.size > 1
      path_components.first
    end

    def last_modified_time(file)
      File.mtime(file)
    end

    def blank?(str)
      str.nil? || str == ""
    end

    def delete_file(file)
      file_path = Pathname.new(file)
      if file_path.file?
        File.delete(file)
        Log.log "Deleted file #{file}"
      end
    end
  end

end
