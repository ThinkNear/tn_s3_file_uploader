require 'rspec'
require 'timecop'
require 'tn_s3_file_uploader/log_uploader'
require 'tn_s3_file_uploader/s3'
require 'tn_s3_file_uploader/file_path_generator'

module TnS3FileUploader

  describe "LogUploader" do
    before do
      @s3 = double(S3)
      @log_uploader = LogUploader.new(@s3)
    end

    after do
      Timecop.return
    end

    def params(input_file_pattern, s3_output_pattern)
      {
          :input_file_pattern => input_file_pattern,
          :s3_output_pattern => s3_output_pattern,
          :file_timestamp_resolution => 300,
          :delete_log_files_flag => true,
          :verbose => true
      }
    end

    describe "#initialize" do
      context "s3 argument invalid" do
        it "should raise an error if the s3 client is nil" do
          expect {
            LogUploader.new(nil)
          }.to raise_error(ArgumentError, 's3 client cannot be nil')
        end
      end
    end

    describe "#upload_log_files" do
      context "Log file pattern is invalid" do
        it "should raise an error if the specified input file pattern is not supplied" do
          expect {
            @log_uploader.upload_log_files(params(nil, 'path/to/folder/file.tar.gz'))
          }.to raise_error(ArgumentError, 'log file pattern cannot be nil')
        end

        it "should raise an error if the specified log file pattern does not have an extension" do
          expect {
            @log_uploader.upload_log_files(params('my/path/to/log_file', 'path/to/event_folder/file.tar.gz'))
          }.to raise_error(ArgumentError, 'my/path/to/log_file is not a valid path. It lacks a file extension.')
        end

        it "should raise an error if the specified log file pattern does not match any files" do
          @file_pattern = '/usr/share/tomcat7/logs/invalid-external-events.log.*.gz'
          allow(Dir).to receive(:[]).with(@file_pattern).and_return([])

          #the proper way to stub calls to %x, make sure to return something
          @log_uploader.should_receive(:`).once.with('df -h').and_return("")
          @log_uploader.should_receive(:`).once.with('ls -l /media/ephemeral0/logs').and_return("")
          @log_uploader.should_receive(:`).once.with('ls -l /usr/share/tomcat7/').and_return("")

          expect {
            @log_uploader.upload_log_files(params(@file_pattern, 'path/to/event_folder/file.tar.gz'))
          }.to raise_error(ArgumentError, '/usr/share/tomcat7/logs/invalid-external-events.log.*.gz did not match any files.')
        end
      end

      context "bucket destination path is invalid" do
        it "should raise an error if s3_output_pattern is not the minimum required number folders" do
          expect {
            @log_uploader.upload_log_files(params('path/to/valid;file.log.*.gz', 'path'))
          }.to raise_error(ArgumentError, 'Bucket destination folder path must have at least two path components, e.g. my/path.')
        end

        it "should raise an error if s3_output_pattern is not the minimum required number folders - trailing slash" do
          expect {
            @log_uploader.upload_log_files(params('path/to/valid;file.log.*.gz', 'path/'))
          }.to raise_error(ArgumentError, 'Bucket destination folder path/ must have at least two path components, e.g. my/path.')
        end
      end

      context "file pattern is valid and matches two files" do
        before do
          @file_pattern = '/logs/filename.log.*.gz'
          @file_to_upload_1 = 'logs/filename.log.1.gz'
          @file_to_upload_2 = 'logs/filename.log.2.gz'
          @s3_output_pattern = 'bucket/logs/%{file-name}.%{file-extension}'
          IPSocket.stub(:getaddress).and_return('10.0.0.1')

          allow(Dir).to receive(:[]).with(@file_pattern).and_return([ @file_to_upload_1, @file_to_upload_2])
          allow(File).to receive(:mtime).with(@file_to_upload_1).and_return(Time.now)
          allow(File).to receive(:mtime).with(@file_to_upload_2).and_return(Time.now)

          expect(@s3).to receive(:upload_file).once.with(@file_to_upload_1, 'bucket', @file_to_upload_1)
          expect(@s3).to receive(:upload_file).once.with(@file_to_upload_2, 'bucket', @file_to_upload_2)
        end

        it "should call the s3 client for all matched input files" do
          @log_uploader.upload_log_files(params(@file_pattern, @s3_output_pattern))
        end

        it "should delete the log files" do
          expect(@log_uploader).to receive(:delete_file).once.with(@file_to_upload_1)
          expect(@log_uploader).to receive(:delete_file).once.with(@file_to_upload_2)

          @log_uploader.upload_log_files(params(@file_pattern, @s3_output_pattern))
        end
      end

      context "GZip log file is using the correct naming convention" do
        before do
          @file_pattern = '/usr/share/tomcat7/logs/invalid-external-events.log.*.gz'
          @file_to_upload = '/usr/share/tomcat7/logs/invalid-external-events.log.1.gz'
          @s3_output_pattern = 'bucket/some/path/to/upload/%{file-name}.%{file-extension}'
          @expected_destination_path = 'some/path/to/upload/invalid-external-events.log.1.gz'
          IPSocket.stub(:getaddress).and_return('10.0.0.1')

          allow(Dir).to receive(:[]).with(@file_pattern).and_return([@file_to_upload])
          allow(File).to receive(:mtime).with(@file_to_upload).and_return(Time.now)
          allow(@s3).to receive(:upload_file).with(any_args).twice
        end

        it "should upload the specified log file using the correct naming convention for destination file" do
          expect(@s3).to receive(:upload_file).once.with(@file_to_upload, 'bucket', @expected_destination_path)

          @log_uploader.upload_log_files(params(@file_pattern, @s3_output_pattern))
        end
      end

      context "LZO log file is using the correct naming convention" do
        before do
          @file_pattern = '/usr/share/tomcat7/logs/invalid-external-events.log.*.lzo'
          @file_to_upload = '/usr/share/tomcat7/logs/invalid-external-events.log.1.lzo'
          @s3_output_pattern = 'bucket/some/path/to/upload/%{file-name}.%{file-extension}'
          @expected_destination_path = 'some/path/to/upload/invalid-external-events.log.1.lzo'
          IPSocket.stub(:getaddress).and_return('10.0.0.1')

          allow(Dir).to receive(:[]).with(@file_pattern).and_return([@file_to_upload])
          allow(File).to receive(:mtime).with(@file_to_upload).and_return(Time.now)
          allow(@s3).to receive(:upload_file).with(any_args)
        end

        it "should upload the specified log file using the correct naming convention for destination file" do
          expect(@s3).to receive(:upload_file).once.with(@file_to_upload, 'bucket', @expected_destination_path)

          @log_uploader.upload_log_files(params(@file_pattern, @s3_output_pattern))
        end
      end
    end
  end
end
