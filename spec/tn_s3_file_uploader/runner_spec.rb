require 'rspec'
require 'tn_s3_file_uploader'
require 'tn_s3_file_uploader/log_uploader'
require 'tn_s3_file_uploader/runner'

module TnS3FileUploader

  describe 'Runner' do

    describe '#run' do
      context 'when options are set and contain mandatory' do
        before do
          @options = {
              :s3_output_pattern => 's3-output-pattern',
              :input_file_pattern => 'input-file-pattern',
              :file_timestamp_resolution => 300
          }
        end

        it 'makes a call to LogUploader with same set of options' do
          expect_any_instance_of(LogUploader).to receive(:upload_log_files).once.with(@options)

          Runner.new(@options).run
        end
      end

      context 'when honeybadger api key option is set' do
        before do
          @options_with_honeybadger = {
              :s3_output_pattern => 'bucket/path/to/output',
              :input_file_pattern => 'path/to/input-file.log.gz',
              :honeybadger_api_key => 'some-api-key'
          }
        end

        it 'configures honeybadger' do
          allow_any_instance_of(LogUploader).to receive(:upload_log_files)
          expect(Honeybadger).to receive(:configure)

          Runner.new(@options_with_honeybadger).run
        end
      end
    end
  end

end
