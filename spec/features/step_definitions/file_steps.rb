require 'timecop'

Before do
  Timecop.freeze(Time.now)
  Dir.mkdir('./target')
end

After do
  Timecop.return
  FileUtils.rm_rf('./target')
end

Given(/^a "([^"]*)" that matches "([^"]*)" files$/) do |input_file_pattern, number_files_matched_str|
  @file_pattern = input_file_pattern
  number_files_matched = number_files_matched_str.to_i
  @files_to_upload = generate_matched_files(input_file_pattern, number_files_matched)
end


def generate_matched_files(input_file_pattern, number_files_matched)
  @files_to_upload = []
  number_files_matched.times do |n|
    file_name = input_file_pattern.gsub('*', "#{n+1}")
    file = populate_file(file_name)
    @files_to_upload << file
  end
end

def populate_file(file_name)
  file = File.new(file_name, "w+")
  file.write("1234\tmy\tfirst\tentry")
  file.write("\n5678\tmy\tsecond\tentry")
  file
ensure
  file.close
end