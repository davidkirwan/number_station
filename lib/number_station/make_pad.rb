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
require "securerandom"
require "json"

module NumberStation
  
  def self.make_otp(pad_path, length, num_pads)
    path = pad_path || Dir.pwd
    len = length.to_i || 250
    num = num_pads.to_i || 5

    NumberStation.log.debug "make_otp"
    pads = {}
    id = rand(0..99999).to_s.rjust(5, "0")
    file_name = File.join(path, "one_time_pad_#{id}.json")
    NumberStation.log.debug "file_name: #{file_name}"

    0.upto(num - 1) {|i| pads[i] = SecureRandom.hex(len)}
    one_time_pads = {
      :id=> id,
      :pads=> pads
    }

    unless File.file?(file_name)
      f = File.open(file_name, "w")
      f.write(one_time_pads.to_json)
      f.close
    else
      raise Exception.new("Exception #{file_name} already exists")
    end
  end

end