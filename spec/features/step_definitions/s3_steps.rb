require 'rspec'
require 'aws-sdk'

Before do
  time = Time.now.utc
  @time_5_mins_ago = time - 300

  @partition_time = Time.at((@time_5_mins_ago.to_f / 300).floor * 300).utc
  @file_timestamp = @partition_time.strftime('%Y%m%d%H%M%S')
  @s3_file_objects = []
end

After do
  @s3_file_objects.each do |s3_file_object|
    s3_file_object.delete
  end

end

Then(/^S3 contains the "([^"]*)" log files that matched "([^"]*)" in the correct destination folder based on "([^"]*)"$/) do | number_files_matched_str, input_file_pattern, s3_output_pattern |
  number_files_matched = number_files_matched_str.to_i
  number_files_matched.times do |n|
    input_file_path = input_file_pattern.gsub('*', "#{n+1}")
    @s3_file_objects << retrieve_s3_file(s3_output_pattern, input_file_path)

    local_file_name = "./target/#{name_from_path(input_file_path)}-file-from-s3.log.gz"
    copy_s3_file_locally(@s3_file_objects.last, local_file_name)

    read_file = File.open(local_file_name, 'r')
    all_lines = read_file.readlines
    expect(all_lines.length).to eql(2)
    expect(all_lines[0]).to eql("1234\tmy\tfirst\tentry\n")
    expect(all_lines[1]).to eql("5678\tmy\tsecond\tentry")
  end
end

def make_substitutions(input_file_path, s3_output_pattern)
  file_name_ext = input_file_path.split('/').last.split('.')
  file_name = file_name_ext[0..-2].join('.')
  file_ext = file_name_ext.last

  subs = {
      '%{file-name}' => file_name,
      '%{file-extension}' => file_ext,
      '%{file-timestamp}' => @file_timestamp,
      '%{ip-address}' => '10-0-0-1'
  }

  subs.each do |macro, sub|
    s3_output_pattern.gsub!(macro, sub)
  end
end

def find_bucket(s3_output_pattern)
  bucket_name = s3_output_pattern.split('/').first
  @s3_client.buckets[bucket_name]
end

def retrieve_s3_file(s3_output_pattern, input_file_path = './target/venice.log.1.lzo')
  bucket = find_bucket(s3_output_pattern)

  object_path = s3_output_pattern.split('/')[1..-1].join('/') # remove bucket
  make_substitutions(input_file_path, object_path)
  object_path = @time_5_mins_ago.strftime(object_path)
  puts "About to retrieve object from #{object_path}"
  bucket.objects[object_path]
end

def copy_s3_file_locally(s3_file, local_file_name)
  File.open(local_file_name, 'wb') do |file|
    s3_file.read do |chunk|
      file.write(chunk)
    end
  end
end

def name_from_path(input_file_pattern)
  input_file_pattern.split('/').last.split('.').first
end