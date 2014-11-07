require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rake/clean'
import 'lib/rake/feature_tests.rake'

# 'rake spec' to run unit tests
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--color"
end

# 'rake tests' to run both unit and feature tests
task :tests => [ :spec, :features ]

# Gem related bundler tasks
# 'rake build' to build gem in pkg directory
# 'rake install' to build gem and install it locally
# 'rake release' to release gem and upload to RubyGems.org
Bundler::GemHelper.install_tasks

# 'rake clean' deletes pkg directory
CLEAN.add 'pkg'

# default rake task cleans pkg directory, runs tests, builds and installs gem
task :default => [ :clean, :tests, :install ]