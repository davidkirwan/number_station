require 'bundler'
require 'fileutils'
Bundler::GemHelper.install_tasks

task :default => :menu

task :menu do
  puts welcomeMsg = <<-MSG
rake build    # Build number_station-x.x.x.gem into the pkg directory
rake install  # Build and install number_station-x.x.x.gem into system gems
rake release  # Create tag vx.x.x and build and push number_station-x.x.x.gem to http://rubygems.org/
MSG
end

desc "Clean up build artifacts"
task :clean do
  FileUtils.rm_rf("./pkg/")
end

