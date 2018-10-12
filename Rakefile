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

