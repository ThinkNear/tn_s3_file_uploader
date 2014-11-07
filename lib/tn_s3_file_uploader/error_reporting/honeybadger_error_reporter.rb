require 'honeybadger'

module TnS3FileUploader

  # Error reporter that uses Honeybadger service to report errors
  class HoneybadgerErrorReporter

    # Configure honeybadger with provided api-key. Assumes api-key is not null
    def initialize(api_key)
      Honeybadger.configure do |config|
        config.api_key = api_key
      end
    end

    def report_error(exception, options = {})
      Honeybadger.notify(exception, options)
    end
  end

end