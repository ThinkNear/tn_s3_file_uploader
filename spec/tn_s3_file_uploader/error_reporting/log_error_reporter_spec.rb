require 'rspec'
require 'stringio'
require 'tn_s3_file_uploader/error_reporting/log_error_reporter'

module TnS3FileUploader

  describe 'LogErrorReporter' do

    describe '#report_error' do
      before do
        @error = double(ArgumentError)
        @error_message = 'This is the error message'
        @error_backtrace = %w(This is the error backtrace)
      end

      context 'when it is called with an exception' do
        it 'prints the options, the exception message and backtrace to the output' do
          output = StringIO.new
          log_error_reporter = LogErrorReporter.new(output)

          expect(@error).to receive(:message).and_return(@error_message)
          expect(@error).to receive(:backtrace).and_return(@error_backtrace)

          options = { :options => { :opt1 => 'val1', :opt2 => 'val2' } }
          log_error_reporter.report_error(@error, options)

          expect(output.string).to eql("#{ options }\nThis is the error message\nThis\nis\nthe\nerror\nbacktrace\n")
        end
      end
    end
  end

end
