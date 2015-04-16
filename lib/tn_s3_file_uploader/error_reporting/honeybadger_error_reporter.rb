require 'honeybadger'
require 'net/http'

module TnS3FileUploader

  # Error reporter that uses Honeybadger service to report errors
  class HoneybadgerErrorReporter

    # Configure honeybadger with provided api-key. Assumes api-key is not null
    def initialize(api_key)
      # configure the hostname on EC2 instances
      hostname = Net::HTTP.get('169.254.169.254', '/latest/meta-data/hostname') rescue nil
      Honeybadger.configure do |config|
        config.api_key = api_key
        config.hostname = hostname if hostname # don't set
      end
    end

    def report_error(exception, options = {})
      Honeybadger.notify(exception, options)
    end
  end

end
