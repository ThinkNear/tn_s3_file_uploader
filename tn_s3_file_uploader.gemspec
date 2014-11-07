require File.join(File.dirname(__FILE__), 'lib', 'tn_s3_file_uploader', 'version')

Gem::Specification.new do |s|
  s.name        = 'tn_s3_file_uploader'
  s.version     = TnS3FileUploader::VERSION
  s.date        = '2014-11-07'
  s.summary     = "Amazon S3 file uploader"
  s.description = "Amazon S3 file uploader that can build folder structures based on timestamp. Typically used in conjunction with Unix's logrotate."
  s.authors     = ["Thinknear.com"]
  s.email       = 'opensource@thinknear.com'
  s.files       = Dir.glob("{bin/**/*,lib/**/*.rb}") + %w(README.md LICENSE.txt)
  s.homepage    = 'http://www.thinknear.com'
  s.license     = 'Copyright (c) ThinkNear 2014, Licensed under APLv2.0'

  s.add_dependency('honeybadger', '~> 1.15')
  s.add_dependency('aws-sdk', '~> 1.35')

  s.executables << 'tn_s3_file_uploader'
end
