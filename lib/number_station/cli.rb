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

require 'thor'
require 'fileutils'

module NumberStation
  class CLI < Thor
    
    # create_config
    desc "create_config [--path PATH]", "copy the sample config to current directory."
    long_desc <<-CREATE_CONFIG_LONG_DESC
      `create_config` will copy the sample config from config/config.json to the current directory. If the
      optional parameter `--path PATH` is passed then this file is copied to the location specified by the 
      PATH parameter.
    CREATE_CONFIG_LONG_DESC
    option :path, :type => :string
    def create_config()
      NumberStation::ConfigReader.read_config()
      config_file_path = File.join(File.dirname(__FILE__), "../../config/conf.json")

      if options[:path]
        path = options[:path]
        unless File.file?(File.join(path, "/conf.json"))
          #write config to path
          NumberStation.log.debug "Copying sample config to #{path}"
          FileUtils.cp(config_file_path, path)
        else
          NumberStation.log.debug "File already exists at #{File.join(path, "/conf.json")}"
        end
      else
        path = Dir.pwd
        unless File.file?(File.join(path, "/conf.json"))
          #write config to local directory the binary was called from
          NumberStation.log.debug "Copying sample config to #{path}"
          FileUtils.cp(config_file_path, path)
        else
          NumberStation.log.debug "File already exists at #{File.join(path, "/conf.json")}"
        end
      end
    end


    # convert_message
    desc "convert_message [MESSAGE]", "Convert a message to phonetic output."
    long_desc <<-CONVERT_MESSAGE_LONG_DESC
      convert_message takes a parameter which should point to a text file containing a message.
      Optional parameters:\n
        --intro [INTRO] should be a text file containing intro message.\n
        --outro [OUTRO] should be a text file containing the outro message.
     
      Final message will be created from intro + message + outro
    CONVERT_MESSAGE_LONG_DESC
    option :intro, :type => :string
    option :outro, :type => :string
    option :mp3, :type => :string
    def convert_message(message)
      NumberStation::ConfigReader.read_config()

      intro_path = options[:intro]
      message_path = message
      outro_path = options[:outro]
      mp3_path = options[:mp3]
      NumberStation.log.debug "intro_path: #{intro_path}" if options[:intro]
      NumberStation.log.debug "message_path: #{message_path}"
      NumberStation.log.debug "outro_path: #{outro_path}" if options[:outro]
      NumberStation.log.debug "mp3_output: " if options[:mp3]

      output = ""
      output += NumberStation.read_message(intro_path) if options[:intro]
      output += NumberStation.read_message(message_path)
      output += NumberStation.read_message(outro_path) if options[:outro]

      NumberStation.log.info "output: #{output}"

      if options[:mp3]
        NumberStation.log.debug "Generating mp3 output: #{mp3_path}"
        NumberStation.run(output, mp3_path)
      end

      return output
    end


    # convert_message
    desc "make_one_time_pad [--path PATH --num NUM --length LENGTH]", "Generate a one time pad of LENGTH containing NUM entries"
    long_desc <<-MAKE_ONE_TIME_PAD_LONG_DESC
    Generate a one time pad of LENGTH containing NUM entries
    Optional parameters:\n
      --path PATH\n
      --num NUM\n
      --length LENGTH

    If no parameters are passed it will generate 5 one time pads in the current 
    directory of size 250 characters.
    MAKE_ONE_TIME_PAD_LONG_DESC
    option :length, :type => :numeric
    option :num_pads, :type => :numeric
    option :path, :type => :string
    def make_one_time_pad()
      NumberStation::ConfigReader.read_config()
      NumberStation.log.debug "make_one_time_pad"

      length = options[:length]
      num_pads = options[:num_pads]
      path = options[:path]

      NumberStation.log.debug "length: #{length}" if options[:length]
      NumberStation.log.debug "num_pads: #{num_pads}" if options[:num_pads]
      NumberStation.log.debug "path: #{path}" if options[:path]

      NumberStation.make_otp(path, length, num_pads)
    end

  end
end
