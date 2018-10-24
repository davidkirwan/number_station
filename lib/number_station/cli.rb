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


    # convert_to_phonetic
    desc "convert_to_phonetic [MESSAGE]", "Convert a message to phonetic output."
    long_desc <<-CONVERT_MESSAGE_LONG_DESC
      convert_message takes a parameter which should point to a text file containing a message.
      Optional parameters:\n
        MESSAGE\n
        --intro [INTRO] should be a text file containing intro message.\n
        --outro [OUTRO] should be a text file containing the outro message.\n
        --mp3 [MP3] output message as an mp3 file.
     
      Final message will be created from intro + message + outro
    CONVERT_MESSAGE_LONG_DESC
    option :intro, :type => :string
    option :outro, :type => :string
    option :mp3, :type => :string
    def convert_to_phonetic(message)
      NumberStation::ConfigReader.read_config()

      intro_path = options[:intro]
      message_path = message
      outro_path = options[:outro]
      mp3_path = options[:mp3]
      NumberStation.log.debug "intro_path: #{intro_path}" if options[:intro]
      NumberStation.log.debug "message_path: #{message_path}"
      NumberStation.log.debug "outro_path: #{outro_path}" if options[:outro]
      NumberStation.log.debug "mp3_path: #{mp3_path}" if options[:mp3]

      output = ""
      output += NumberStation.to_phonetic(intro_path) if options[:intro]
      output += NumberStation.to_phonetic(message_path)
      output += NumberStation.to_phonetic(outro_path) if options[:outro]
      NumberStation.log.info "output: #{output}"

      if options[:mp3]
        NumberStation.log.debug "Generating mp3 output: #{mp3_path}"
        NumberStation.write_mp3(output, mp3_path)
      end
      return output
    end


    # make_one_time_pad
    desc "make_one_time_pad [--path PATH --numpads NUM --length LENGTH]", "Generate a one time pad of LENGTH containing NUM entries"
    long_desc <<-MAKE_ONE_TIME_PAD_LONG_DESC
    Generate a one time pad of LENGTH containing NUM entries
    Parameters:\n
      --path PATH\n
      --numpads NUM\n
      --length LENGTH

    If no parameters are passed it will generate 5 one time pads in the current 
    directory of size 250 characters.
    MAKE_ONE_TIME_PAD_LONG_DESC
    option :length, :type => :numeric
    option :numpads, :type => :numeric
    option :path, :type => :string
    def make_one_time_pad()
      NumberStation::ConfigReader.read_config()
      NumberStation.log.debug "make_one_time_pad"

      length = options[:length]
      numpads = options[:numpads]
      path = options[:path]
      NumberStation.log.debug "length: #{length}" if options[:length]
      NumberStation.log.debug "numpads: #{numpads}" if options[:numpads]
      NumberStation.log.debug "path: #{path}" if options[:path]

      NumberStation.make_otp(path, length, numpads)
    end


    # encrypt message with a pad
    desc "encrypt_message [MESSAGE --numpad NUMPAD --padpath PADPATH]", "Encrypt a message using the key: NUMPAD in one time pad PADPATH"
    long_desc <<-ENCRYPT_MESSAGE_LONG_DESC
    Encrypt a message using key NUMPAD in one-time-pad PADPATH
    Parameters:\n
      MESSAGE
      --numpad NUMPAD\n
      --padpath PADPATH

    ENCRYPT_MESSAGE_LONG_DESC
    option :numpad, :type => :string
    option :padpath, :type => :string
    def encrypt_message(message)
      NumberStation::ConfigReader.read_config()
      NumberStation.log.debug "encrypt_message"

      message_data = File.read(message)
      numpad = options[:numpad]
      padpath = options[:padpath]

      NumberStation.log.debug "message: #{message}" if options[:message]
      NumberStation.log.debug "numpad: #{numpad}" if options[:numpad]
      NumberStation.log.debug "padpath: #{padpath}" if options[:padpath]

      enc_m = NumberStation.encrypt_message(message_data, padpath, numpad)
      NumberStation.log.debug "encrypted_message: #{enc_m}"
    end


    # decrypt message with a pad
    desc "decrypt_message [MESSAGE --numpad NUMPAD --padpath PADPATH]", "Decrypt a message using the key: NUMPAD in one time pad PADPATH"
    long_desc <<-DECRYPT_MESSAGE_LONG_DESC
    Encrypt a message using key NUMPAD in one-time-pad PADPATH
    Parameters:\n
      MESSAGE
      --numpad NUMPAD\n
      --padpath PADPATH

    DECRYPT_MESSAGE_LONG_DESC
    option :numpad, :type => :string
    option :padpath, :type => :string
    def decrypt_message(message)
      NumberStation::ConfigReader.read_config()
      NumberStation.log.debug "decrypt_message"

      message_data = File.read(message)
      numpad = options[:numpad]
      padpath = options[:padpath]

      NumberStation.log.debug "message: #{message}"
      NumberStation.log.debug "numpad: #{numpad}" if options[:numpad]
      NumberStation.log.debug "padpath: #{padpath}" if options[:padpath]

      decrypt_m = NumberStation.decrypt_message(message_data, padpath, numpad)
      NumberStation.log.debug "decrypted_message: #{decrypt_m}"
    end


  end
end
