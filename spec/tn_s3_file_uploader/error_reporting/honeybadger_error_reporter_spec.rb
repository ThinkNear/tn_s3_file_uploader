require 'rspec'
require 'tn_s3_file_uploader/error_reporting/honeybadger_error_reporter'

module TnS3FileUploader

  describe 'HoneybadgerErrorReporter' do
    describe '#report_error' do
      context 'when it is called' do
        it 'calls to Honeybadger#notify' do
          expect(Honeybadger).to receive(:configure)
          expect(Honeybadger).to receive(:notify)

          honeybadger_error_reporter = HoneybadgerErrorReporter.new('some_api_key')
          honeybadger_error_reporter.report_error(ArgumentError.new)
        end
      end
    end
  end

end
