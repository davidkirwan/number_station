=begin
 Ruby Number Station
 Author: David Kirwan https://gitub.com/davidkirwan
 Licence: GPL 3.0
 NumberStation is a collection of utilities to aid in the running of a number station
    Copyright (C) 2018  David Kirwan

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
=end

require 'bundler'
require 'fileutils'

# Ensure we load from local lib directory, not installed gem
# This must happen before requiring number_station/version
lib = File.expand_path('lib', __FILE__)
# Remove gem paths that might interfere
gem_paths = $LOAD_PATH.select { |p| p.include?('gems') && p.include?('number_station') }
gem_paths.each { |p| $LOAD_PATH.delete(p) }
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Load version from local source
require_relative 'lib/number_station/version'

Bundler::GemHelper.install_tasks

task :default => :menu

desc "Show available rake tasks"
task :menu do
  puts <<-MSG
Available tasks:

  rake build      # Build number_station-x.x.x.gem into the pkg directory
  rake install    # Build and install number_station-x.x.x.gem into system gems
  rake release    # Create tag vx.x.x and build and push number_station-x.x.x.gem to http://rubygems.org/
  rake clean      # Clean up build artifacts (.gem files and pkg directory)
  rake version    # Show the current version
  rake validate   # Validate the gemspec
  rake console    # Start an interactive console with the gem loaded

MSG
end

desc "Clean up build artifacts"
task :clean do
  FileUtils.rm_rf("./pkg/")
  FileUtils.rm_f(Dir.glob("*.gem"))
  puts "Cleaned build artifacts"
end

desc "Show the current version"
task :version do
  puts "number_station version: #{NumberStation::VERSION}"
end

desc "Validate the gemspec"
task :validate do
  require 'rubygems/specification'
  
  begin
    spec = Gem::Specification.load('number_station.gemspec')
    puts "✓ Gemspec is valid"
    puts "  Name: #{spec.name}"
    puts "  Version: #{spec.version}"
    puts "  Dependencies: #{spec.dependencies.map(&:name).join(', ')}"
  rescue => e
    puts "✗ Gemspec validation failed: #{e.message}"
    exit 1
  end
end

desc "Start an interactive console"
task :console do
  require 'irb'
  require 'number_station'
  ARGV.clear
  IRB.start
end

# Clean before building
task :build => :clean

