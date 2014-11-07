module TnS3FileUploader

  # Simple error reporter that logs exception message and backtrace to stdout
  class LogErrorReporter

    def initialize(output)
      @output = output
    end

    def report_error(exception, options ={} )
      @output.puts options
      @output.puts exception.message
      @output.puts exception.backtrace.join("\n")
    end
  end

end