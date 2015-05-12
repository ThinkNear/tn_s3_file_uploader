require 'rspec'
require 'tn_s3_file_uploader/file_path_generator'

module TnS3FileUploader

  describe "FilePathGenerator" do
    before do
      @default_input_file = 'path/for/some-file.tar.gz'
      @default_s3_output_pattern = 'bucket/y=%Y/m=%m/d=%d/h=%H'
      @file_timestamp = "20140608060000"

      @params_with_default_s3_pattern = {
          :s3_output_pattern => @default_s3_output_pattern,
          :file_timestamp_resolution => 300
      }
    end
    describe "#dest_full_path_for" do
      before do
        FilePathGenerator.any_instance.stub(:local_ip).and_return('10.0.0.1')
        @time = Time.utc(2014, 6, 8, 6, 9, 0)
        @file = '/path/to/bids.log.1.gz'
      end

      context "when the specified time partition includes minute" do
        it "should include minute in the path" do
          time = Time.utc(2014, 6, 18, 0, 1, 2)
          @file_path = FilePathGenerator.new( {
              :s3_output_pattern => "bucket/y=%Y/m=%m/d=%d/h=%H/mm=00",
              :file_timestamp_resolution => 300
          } )

          @partition_path = @file_path.dest_full_path_for(time, @default_input_file)
          expect(@partition_path).to eql("y=2014/m=06/d=17/h=23/mm=00")
        end
      end

      context "when the partition has full words" do
        it "should include them in the partition path" do
          time = Time.utc(2014, 6, 18, 0, 1, 2)
          @file_path = FilePathGenerator.new( {
              :s3_output_pattern => "bucket/year=%Y/month=%m/day=%d/hour=%H",
              :file_timestamp_resolution => 300
          } )

          @partition_path = @file_path.dest_full_path_for(time, @default_input_file)
          expect(@partition_path).to eql("year=2014/month=06/day=17/hour=23")
        end
      end

      context "when specified time of 5 mins prior is the previous day " do
        before do
          time = Time.utc(2014, 6, 18, 0, 1, 2)
          @file_path = FilePathGenerator.new( @params_with_default_s3_pattern)
          @expected_path = "y=2014/m=06/d=17/h=23"

          @partition_path = @file_path.dest_full_path_for(time, 'path/for/some-file.tar.gz')
        end

        it "should return the correct partition " do
          expect(@partition_path).to eql(@expected_path)
        end
      end

      context "when specified time of 5 mins prior is the previous year" do
        before do
          time = Time.utc(2014, 1, 1, 0, 2, 2)
          @expected_path = "y=2013/m=12/d=31/h=23"
          @file_path = FilePathGenerator.new( @params_with_default_s3_pattern)

          @partition_path = @file_path.dest_full_path_for(time, @default_input_file)
        end

        it "should return the correct partition" do
          expect(@partition_path).to eql(@expected_path)
        end
      end

      context "when partition path is in the middle of an hour" do
        before do
          time = Time.utc(2014, 6, 18, 7, 50, 2)
          @expected_path = "y=2014/m=06/d=18/h=07"
          @file_path = FilePathGenerator.new( @params_with_default_s3_pattern)

          @partition_path = @file_path.dest_full_path_for(time, @default_input_file)
        end

        it "should return the correct partition" do
          expect(@partition_path).to eql(@expected_path)
        end
      end

      context "when the partition is 5 mins prior to the previous hour" do
        before do
          time = Time.utc(2014, 6, 18, 7, 2, 2)
          @expected_path = "y=2014/m=06/d=18/h=06"
          @file_path = FilePathGenerator.new(@params_with_default_s3_pattern)

          @partition_path = @file_path.dest_full_path_for(time, @default_input_file)
        end

        it "should return the correct partition" do
          expect(@partition_path).to eql(@expected_path)
        end
      end

      context "when an output file pattern macro is given" do
        before do
          @expected_file_name = "10-0-0-1.#{@file_timestamp}.bids.log.1.gz"
          @file_path = FilePathGenerator.new( {
              :s3_output_pattern => "bucket/%{ip-address}.%{file-timestamp}.%{file-name}.%{file-extension}",
              :file_timestamp_resolution => 300
          })
        end

        it "substitutes the macros and generates output file name based on the provided pattern" do
          actual_file_name = @file_path.dest_full_path_for(@time, @file)
          expect(actual_file_name).to eql(@expected_file_name)
        end
      end

      context "when input file does not contain an extension" do
        before do
          @expected_file_name = "filename.#{@file_timestamp}"
          @file = 'filename'
          @file_path = FilePathGenerator.new( {
              :s3_output_pattern => "bucket/%{file-name}.%{file-timestamp}%{file-extension}",
              :file_timestamp_resolution => 300
          })
        end

        it "substitutes the resulting filename as if extension is empty" do
          actual_file_name = @file_path.dest_full_path_for(@time, @file)
          expect(actual_file_name).to eql(@expected_file_name)
        end
      end

    end

    describe "#generate_file_timestamp" do
      before do
        @s3_timestamp_pattern = 'bucket/%Y%m%d%H%M%S'
      end

      context "when specified time is a second before the next partition window" do
        partitions = [ 5, 10, 15, 20, 30 ]

        partitions.each do |partition_seconds|
          before do
            time = Time.utc(2014, 6, 18, 20, 50, 2 * partition_seconds - 1)
            @expected_timestamp = "20140618205000"
            @file_path = FilePathGenerator.new( {
                :s3_output_pattern => @s3_timestamp_pattern,
                :file_timestamp_resolution => partition_seconds
            } )

            @actual_file_timestamp = @file_path.dest_full_path_for(time, @default_input_file)
          end

          it "should round to exact seconds 00 for a #{partition_seconds} seconds window" do
            expect(@actual_file_timestamp).to eql(@expected_timestamp)
          end
        end
      end

      context "when specified time is one second past the minute" do
        partitions_to_expected_timestamp = {
            5 => "20140618200455",
            10 => "20140618200450",
            15 => "20140618200445",
            20 => "20140618200440",
            30 => "20140618200430"
        }

        partitions_to_expected_timestamp.each do |partition_seconds, expected_timestamp|
          before do
            time_a_second_after_minute = Time.utc(2014, 6, 18, 20, 5, 1)
            @expected_result = expected_timestamp
            @file_path = FilePathGenerator.new( {
                                                    :s3_output_pattern => @s3_timestamp_pattern,
                                                    :file_timestamp_resolution => partition_seconds } )

            @actual_file_timestamp = @file_path.dest_full_path_for(time_a_second_after_minute, @default_input_file)
          end

          it "should return timestamp #{@expected_result} for a #{partition_seconds} seconds window" do
            expect(@actual_file_timestamp).to eql(@expected_result)
          end
        end
      end

      context "when specified time is one minute past the day" do
        partitions_to_expected_timestamp = {
            300 => "20140617235500", # 5 minutes window
            600 => "20140617235000", # 10 minutes window
            900 => "20140617234500", # 15 minutes window
            1200 => "20140617234000", # 20 minutes window
            1800 => "20140617233000" # 30 minutes window
        }

        partitions_to_expected_timestamp.each do |partition_minutes, expected_timestamp|
          before do
            time = Time.utc(2014, 6, 18, 0, 1, 0)
            @file_path = FilePathGenerator.new( {
                :s3_output_pattern => @s3_timestamp_pattern,
                :file_timestamp_resolution => partition_minutes
            } )
            @expected_result = expected_timestamp
            @actual_file_timestamp = @file_path.dest_full_path_for(time, @default_input_file)
          end

          it "should return #{@expected_result} for a #{partition_minutes / 60} minutes window" do
            expect(@actual_file_timestamp).to eql(@expected_result)
          end
        end
      end

      context "when specified time in on the time window boundary" do
        partitions = [5, 10, 15, 20, 30]

        partitions.each do |partition_seconds|
          before do
            time = Time.utc(2014, 6, 18, 15, 0, partition_seconds)
            @expected_timestamp = "20140618150000"
            @file_path = FilePathGenerator.new({ :s3_output_pattern => @s3_timestamp_pattern,
                                                                     :file_timestamp_resolution => partition_seconds } )

            @actual_file_timestamp = @file_path.dest_full_path_for(time, @default_input_file)
          end

          it "returns a timestamp with rounded up seconds for a #{partition_seconds} seconds window" do
            expect(@actual_file_timestamp).to eql(@expected_timestamp)
          end
        end
      end
    end
    
    describe "#local_ip" do
      context "when udp and hostname resolvement fails" do
        before do
          @file_path = FilePathGenerator.new( { :s3_output_pattern => @s3_timestamp_pattern,
                                                     :file_timestamp_resolution => 300,
                                                     :udp_resolve_ip => '10.100.1.1' } )
          
          @file_path.stub(:udp_resolve_ip).and_return('a.b.c.d')
          @file_path.stub(:hostname_resolve_ip).and_return('a.b.c.d')
          
          @expected_ip = '0.0.0.0'
          @actual_ip = @file_path.send(:local_ip)
        end
        
        it "should return a default ip" do
          expect(@actual_ip).to eql(@expected_ip)
        end
      end
    end
    
    context "when udp fails and hostname resolvement succesds" do
      before do
        @file_path = FilePathGenerator.new( { :s3_output_pattern => @s3_timestamp_pattern,
                                                   :file_timestamp_resolution => 300,
                                                   :udp_resolve_ip => '10.100.1.1' } )
        @file_path.stub(:udp_resolve_ip).and_return('a.b.c.d')
        @file_path.stub(:hostname_resolve_ip).and_return('10.0.0.1')

        @expected_ip = '10.0.0.1'
        @actual_ip = @file_path.send(:local_ip)
      end
      
      it "should return hostname resolved ip" do
        expect(@actual_ip).to eql(@expected_ip)
      end
    end
    
    context "when udp resolvement succeeds" do
      before do
        @file_path = FilePathGenerator.new( { :s3_output_pattern => @s3_timestamp_pattern,
                                                   :file_timestamp_resolution => 300,
                                                   :udp_resolve_ip => '10.100.1.1' } )
        @file_path.stub(:udp_resolve_ip).and_return('10.0.1.1')

        @expected_ip = '10.0.1.1'
        @actual_ip = @file_path.send(:local_ip)
      end
      
      it "should return udp resolved ip" do
        expect(@actual_ip).to eql(@expected_ip)
      end
    end

  end
end
