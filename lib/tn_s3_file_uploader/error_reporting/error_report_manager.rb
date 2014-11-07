require 'singleton'
require 'tn_s3_file_uploader/error_reporting/log_error_reporter'

module TnS3FileUploader

  # Singleton that instruments all error reporters.
  # Register your error reporter by calling `ErrorReportManager.instance.register_error_reporter`
  # error reporters provided have to specify a method with name `report_error`
  class ErrorReportManager
    include Singleton

    def initialize
      @error_reporters = []
    end

    def register_error_reporter(error_reporter)
      unless error_reporter.respond_to?(:report_error)
        raise ArgumentError, 'Provided error_reporter instance does not support the report_error method'
      end

      @error_reporters << error_reporter
    end

    def count_error_reporters
      @error_reporters.count
    end

    def report_error(exception, options = {})
      @error_reporters.each do |error_reporter|
        error_reporter.report_error(exception, options)
      end
    end
  end

end
