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

module NumberStation
  class ConfigReader

    def self.read_config()
      begin
        config_file_path = File.join(Dir.home, "number_station/conf.json")
        NumberStation.set_data( JSON.parse(File.read(config_file_path)) )
        NumberStation.set_log( Logger.new(STDOUT) )
        NumberStation.log.level = NumberStation.data["logging"]["level"]
        NumberStation.log.debug "Reading in config file: #{config_file_path}"
      rescue Exception => e
        config_file_path = File.join(File.dirname(__FILE__), "../../config/conf.json")
        NumberStation.set_data( JSON.parse(File.read(config_file_path)) )
        NumberStation.set_log( Logger.new(STDOUT) )
        NumberStation.log.level = NumberStation.data["logging"]["level"]
        NumberStation.log.debug "Reading in default config file: #{config_file_path}"
      end
      NumberStation.log.debug "NumberStation::ConfigReader#read_config"
    end

  end
end
