require 'cucumber'
require 'cucumber/rake/task'

# 'rake features' to run feature tests
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = '--verbose --format pretty spec/features'
end

task :run_fake_s3 do
  @fakes3_dir = 'fake-s3-dir'
  mkdir @fakes3_dir unless File.exists?(@fakes3_dir)
  @fakes3_pid = fork { exec "fakes3 server -h localhost -r #{@fakes3_dir} -p 4515" }
  Process.detach(@fakes3_pid)
end

task :stop_fake_s3 do
  begin
    Process.kill('SIGINT', @fakes3_pid)
  ensure
    rm_rf @fakes3_dir if File.exists?(@fakes3_dir)
  end
end

# Run fake s3 before running feature tests
# Stop fake S3 after running feature tests
Rake::Task['features'].enhance [:run_fake_s3] do
  Rake::Task['stop_fake_s3'].invoke
end
