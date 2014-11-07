require 'rspec'
require 'tn_s3_file_uploader/cli_parser'

module TnS3FileUploader

  describe 'CliParser' do
    before do
      @cli_parser = CliParser.new
      @valid_args = %w(--s3-output-pattern=s3-output-pattern --input-file-pattern=input-file-pattern)
    end

    describe '#parse_cmd_line' do

      context 'when a mandatory option is missing' do
        before { @empty_args = [] }

        it 'raises a missing argument error' do
          expect{ @cli_parser.parse_cmd_line(@empty_args) }.to raise_error(OptionParser::MissingArgument)
        end
      end

      context 'when all mandatory options are set' do
        before do
          @expected = {
              :s3_output_pattern => 's3-output-pattern',
              :input_file_pattern => 'input-file-pattern',
              :file_timestamp_resolution => 300
          }
        end

        it 'returns a hash of the provided options' do
          expect(@cli_parser.parse_cmd_line(@valid_args)).to eql(@expected)
        end
      end

      context 'when a negative file timestamp resolution is provided' do
        before { @valid_args << '--file-timestamp-resolution=-100' }

        it 'defaults to a file timestamp resolution of 300 (5 minutes)' do
          expect(@cli_parser.parse_cmd_line(@valid_args)).to include(:file_timestamp_resolution => 300)
        end
      end

      context 'when a zero timestamp resolution is provided' do
        before { @valid_args << '--file-timestamp-resolution=0' }

        it 'defaults to a file timestamp resolution of 300 (5 minutes)' do
          expect(@cli_parser.parse_cmd_line(@valid_args)).to include(:file_timestamp_resolution => 300)
        end
      end

    end

  end

end
