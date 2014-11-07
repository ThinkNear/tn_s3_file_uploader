require 'rspec'
require 'tn_s3_file_uploader/error_reporting/error_report_manager'

module TnS3FileUploader

  describe 'ErrorReportManager' do

    class ValidErrorReporter
      def report_error(exc, options = {})
        # do nothing
      end
    end

    class InvalidErrorReporter
    end

    describe '#register_error_reporter' do
      before { @error_report_manager = ErrorReportManager.instance }

      context 'when the provided error_reporter does not support the report_error method' do
        it 'raises an argument error exception' do
          invalid_error_reporter = InvalidErrorReporter.new
          expect { @error_report_manager.register_error_reporter(invalid_error_reporter) }.to raise_error(ArgumentError)
        end

        context 'when the provided error reporter supports the report_error method' do
          it 'adds the reporter to the list of reporters' do
            valid_error_reporter = ValidErrorReporter.new

            @error_report_manager.register_error_reporter(valid_error_reporter)

            expect(@error_report_manager.count_error_reporters).to eql(1)
          end
        end

      end
    end

    describe '#report_error' do
      before { @error_report_manager = ErrorReportManager.instance }

      context 'when a number of error reporters are registered in the manager' do
        it 'calls the #report_error method in each one of them' do
          valid_error_reporter_1 = ValidErrorReporter.new
          valid_error_reporter_2 = ValidErrorReporter.new

          @error_report_manager.register_error_reporter(valid_error_reporter_1)
          @error_report_manager.register_error_reporter(valid_error_reporter_2)

          expect(valid_error_reporter_1).to receive(:report_error).once
          expect(valid_error_reporter_2).to receive(:report_error).once

          @error_report_manager.report_error(nil)
        end
      end
    end
  end

end
