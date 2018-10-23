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
require 'pastel'
require 'json'
require 'logger'
require 'number_station/cli'
require 'number_station/config_reader'
require 'number_station/make_onetime_pad'
require 'number_station/phonetic_conversion'
require 'number_station/version'


module NumberStation

  def self.hexlify(s)
    a = []
    s.each_byte do |b|
      a << sprintf('%02X', b)
    end
    a.join
  end
 
  def self.unhexlify(s)
    a = s.split
    return a.pack('H*')
  end

  def self.command?(name)
    `which #{name}`
    $?.success?
  end  

  def self.set_log(log)
    @log = log
  end

  def self.log()
    return @log
  end

  def self.set_data(data)
    @data = data
  end

  def self.data()
    return @data
  end

end
