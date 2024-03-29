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
      Sample Intro and Outro messages are also copied to this directory. If you wish to automatically append
      these messages, change the conf.json boolean.
    CREATE_CONFIG_LONG_DESC
    option :path, :type => :string
    def create_config()
      config_file_path = File.join(File.dirname(__FILE__), "../../resources/conf.json")
      intro_file_path = File.join(File.dirname(__FILE__), "../../resources/intro_message.txt")
      outro_file_path = File.join(File.dirname(__FILE__), "../../resources/outro_message.txt")

      options[:path] ? path = options[:path] : path = File.join(Dir.home, "/number_station")

      unless Dir.exist?(path) then FileUtils.mkdir(path) end
      unless File.file?(File.join(path, "conf.json")) then FileUtils.cp(config_file_path, File.join(path, "conf.json")) end
      unless File.file?(File.join(path, "intro_message.txt")) then FileUtils.cp(intro_file_path, File.join(path, "intro_message.txt")) end
      unless File.file?(File.join(path, "outro_message.txt")) then FileUtils.cp(outro_file_path, File.join(path, "outro_message.txt")) end
      NumberStation::ConfigReader.read_config()
      NumberStation.log.debug "create_config completed"
    end


    # convert_to_phonetic
    desc "convert_to_phonetic [MESSAGE_PATH]", "Convert a message to phonetic output."
    long_desc <<-CONVERT_MESSAGE_LONG_DESC
      convert_message takes a parameter which should point to a text file containing a message.
        MESSAGE_PATH\n
      Optional parameters:\n
        --intro [INTRO_PATH] should be a text file containing intro message. Overrides value in conf.json\n
        --outro [OUTRO_PATH] should be a text file containing the outro message. Overrides value in conf.json\n
        --mp3 [MP3] output message as an mp3 file.

      Final message will be created from intro + message + outro
    CONVERT_MESSAGE_LONG_DESC
    option :intro, :type => :string
    option :outro, :type => :string
    option :mp3, :type => :string
    def convert_to_phonetic(message_path)
      NumberStation::ConfigReader.read_config()

      if options[:intro]
        intro_path = options[:intro]
        intro = NumberStation.to_phonetic(intro_path)
      elsif NumberStation.data["resources"]["intro"]["enabled"]
        intro_path = NumberStation.data["resources"]["intro"]["template"]
        intro = NumberStation.to_phonetic(intro_path)
      else
        intro_path = ""
      end

      if options[:outro]
        outro_path = options[:outro]
        outro = NumberStation.to_phonetic(outro_path)
      elsif NumberStation.data["resources"]["outro"]["enabled"]
        outro_path = NumberStation.data["resources"]["outro"]["template"]
        outro = NumberStation.to_phonetic(outro_path)
      else
        outro_path = ""
        outro = ""
      end
      NumberStation.log.debug "intro enabled: #{NumberStation.data["resources"]["intro"]["enabled"]} path: #{intro_path}"
      NumberStation.log.debug "message_path: #{message_path}"
      NumberStation.log.debug "outro enabled: #{NumberStation.data["resources"]["outro"]["enabled"]} path: #{outro_path}"

      message = NumberStation.to_phonetic(message_path)
      output = intro + message + outro
      NumberStation.log.info "output: #{output}"

      if options[:mp3]
        mp3_path = options[:mp3]
        NumberStation.log.debug "mp3_path: #{mp3_path}" if options[:mp3]
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


    # version
    desc "version", "Print the version of the Number Stations gem."
    long_desc <<-VERSION_LONG_DESC
    Prints the version of the Number Stations gem.
    VERSION_LONG_DESC
    def version()
      NumberStation::ConfigReader.read_config()
      NumberStation.log.debug "Version: #{NumberStation::VERSION}"
    end

    def self.exit_on_failure?()
      false
    end
  end
end
