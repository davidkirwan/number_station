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
require 'json'
require 'logger'
require 'number_station/cli'
require 'number_station/config_reader'
require 'number_station/encrypt_message'
require 'number_station/decrypt_message'
require 'number_station/make_onetime_pad'
require 'number_station/phonetic_conversion'
require 'number_station/examine_pads'
require 'number_station/GLaDOS_espeak'
require 'number_station/version'


module NumberStation
  def self.command?(name)
    `which #{name}`
    $?.success?
  end

  def self.set_log(log)
    @log = log
  end

  def self.log
    @log
  end

  def self.set_data(data)
    @data = data
  end

  def self.data
    @data
  end

  def self.agent_list
    return [] unless @data && @data["agent_list"]
    
    # Handle backward compatibility: if agent_list contains strings, convert them
    agents = @data["agent_list"]
    if agents.is_a?(Array) && agents.first.is_a?(String)
      # Old format: array of strings, convert to hashes
      agents.map do |name|
        {
          "name" => name,
          "location" => nil,
          "handler_codeword" => nil,
          "start_date" => nil,
          "end_date" => nil,
          "active" => false
        }
      end
    else
      # New format: array of hashes
      agents
    end
  end

  def self.find_agent_by_name(name)
    agent_list.find { |agent| agent["name"] == name }
  end

  def self.active_agents
    agent_list.select { |agent| agent["active"] == true }
  end
end
