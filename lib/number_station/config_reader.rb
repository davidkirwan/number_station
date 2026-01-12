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

require 'yaml'
require 'fileutils'
require 'date'

module NumberStation
  class ConfigReader
    def self.read_config
      config_path = user_config_path || default_config_path
      load_config(config_path)
    end

    def self.user_config_path
      yaml_path = File.join(Dir.home, "number_station", "conf.yaml")
      json_path = File.join(Dir.home, "number_station", "conf.json")
      
      # Prefer YAML, but support JSON for backward compatibility
      return yaml_path if File.exist?(yaml_path)
      return json_path if File.exist?(json_path)
      nil
    end

    def self.default_config_path
      yaml_path = File.join(File.dirname(__FILE__), "../../resources/conf.yaml")
      json_path = File.join(File.dirname(__FILE__), "../../resources/conf.json")
      
      # Prefer YAML, but support JSON for backward compatibility
      return yaml_path if File.exist?(yaml_path)
      return json_path if File.exist?(json_path)
      yaml_path  # Default to YAML path
    end

    def self.load_config(config_path)
      config_data = if config_path.end_with?('.yaml') || config_path.end_with?('.yml')
        # Use safe_load with permitted classes to handle Date objects
        YAML.safe_load(File.read(config_path), permitted_classes: [Date, Time], aliases: true)
      else
        require 'json'
        JSON.parse(File.read(config_path))
      end
      
      NumberStation.set_data(config_data)
      setup_logger(config_data["logging"]["level"])
      NumberStation.log.debug "Reading in config file: #{config_path}"
    rescue StandardError => e
      # Ensure logger exists before trying to log
      unless NumberStation.log
        setup_logger(Logger::WARN)
      end
      NumberStation.log.error "Failed to load config: #{e.message}"
      raise
    end

    def self.setup_logger(level)
      NumberStation.set_log(Logger.new(STDOUT))
      NumberStation.log.level = level
    end

    def self.save_config(config_data = nil)
      config_data ||= NumberStation.data
      config_path = user_config_path || File.join(Dir.home, "number_station", "conf.yaml")
      
      # Ensure directory exists
      FileUtils.mkdir_p(File.dirname(config_path))
      
      # Convert Date/Time objects to strings before saving
      sanitized_data = sanitize_for_yaml(config_data.dup)
      
      # Save as YAML
      File.write(config_path, sanitized_data.to_yaml)
      NumberStation.set_data(config_data)  # Update in-memory data (keep original format)
      NumberStation.log.debug "Saved config file: #{config_path}"
      config_path
    rescue StandardError => e
      # Ensure logger exists before trying to log
      unless NumberStation.log
        setup_logger(Logger::WARN)
      end
      NumberStation.log.error "Failed to save config: #{e.message}"
      raise
    end

    def self.sanitize_for_yaml(data)
      case data
      when Hash
        data.each_with_object({}) do |(key, value), result|
          result[key] = sanitize_for_yaml(value)
        end
      when Array
        data.map { |item| sanitize_for_yaml(item) }
      when Date, Time
        data.to_s
      else
        data
      end
    end

    private
  end
end
