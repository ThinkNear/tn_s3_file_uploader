require 'rspec'
require 'aws-sdk'
require 'tn_s3_file_uploader/s3'
require 'tmpdir'
require 'honeybadger'

module TnS3FileUploader

  describe "S3" do

    before do
      @s3_client = double(AWS::S3)
      @s3_bucket_collection = double(AWS::S3::BucketCollection)
      @s3_bucket = double(AWS::S3::Bucket)
      @s3_object_collection = double(AWS::S3::ObjectCollection)
      @s3_object = double(AWS::S3::S3Object)

      @s3_file = S3.new(@s3_client)

      allow(@s3_client).to receive(:buckets).and_return(@s3_bucket_collection)

      @s3_file.stub(:sleep)
    end

    describe "#upload_file" do
      context "When all arguments valid" do
        before do
          @bucket = "mybucket"
          @s3_output_path = "path/to/my/object/my_destination_file.tar.gz"
          @local_file_path = "#{Dir.tmpdir}/myfile.tar.gz"
          File.open(@local_file_path, 'wb+') { |file| file.write("my first entry") }

          allow(@s3_bucket_collection).to receive(:[]).with("mybucket").and_return(@s3_bucket)
          allow(@s3_bucket).to receive(:objects).and_return(@s3_object_collection)
          allow(@s3_object_collection).to receive(:[]).with(@s3_output_path).and_return(@s3_object)
        end

        it "should upload the file to the correct location" do
          expect(@s3_client).to receive(:buckets).once
          expect(@s3_bucket).to receive(:objects).once
          expect(@s3_object).to receive(:write).once.with(any_args) { |file_arg| file_arg.path.should == @local_file_path }

          @s3_file.upload_file(@local_file_path, @bucket, @s3_output_path)
        end

        context "when error writing to S3" do
          before do
            allow(@s3_client).to receive(:config).and_return(AWS::Core::Configuration.new)
            allow(@s3_object).to receive(:write).and_raise(IOError)
          end
          it "should retry 3 times on error" do
            expect(@s3_client.config.credential_provider).to receive(:refresh).exactly(3).times
            expect(@s3_file).to receive(:upload).exactly(4).times.and_call_original

            expect {
              @s3_file.upload_file(@local_file_path, @bucket, @s3_output_path)
            }.to raise_error(IOError)
          end
        end
      end

      context "When invalid file" do
        it "should raise an error if file is nil" do
          expect {
            @s3_file.upload_file(nil, 'bucket', 'valid/path/to/something/destination_file_name.log.gz')
          }.to raise_error(ArgumentError, 'file cannot be nil')
        end

        it "should raise an error if file is not a valid file" do
          expect {
            @s3_file.upload_file('path/to/non/existent/file.log.1.gz', 'bucket', 'valid/path/to/something/destination_file_name.log.gz')
          }.to raise_error(ArgumentError, 'path/to/non/existent/file.log.1.gz is not a valid file')
        end
      end

      context "When invalid bucket" do
        it "should raise an error if bucket is nil" do
          expect {
            @s3_file.upload_file('path/to/non/existent/file.log.1.gz', nil, 'valid/path/to/something/destination_file_name.log.gz')
          }.to raise_error(ArgumentError, 'bucket cannot be nil')
        end
      end

      context "When invalid destination path" do
        it "should raise an error if path is nil" do
          expect {
            @s3_file.upload_file('path/to/non/existent/file.log.1.gz', 'bucket', nil)
          }.to raise_error(ArgumentError, 'dest_path cannot be nil')
        end
      end

    end
  end

end
