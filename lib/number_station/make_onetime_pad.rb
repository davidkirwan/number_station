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
require "time"
require "date"

module NumberStation
  def self.make_otp(pad_path, length, num_pads, agent_name = nil)
    path = pad_path || Dir.pwd
    len = length || 500
    num = num_pads || 500

    # Round length up to nearest multiple of 5
    len = round_up_to_multiple_of_5(len.to_i)

    # Generate date-based filename with uniqueness component
    date_str = Date.today.strftime("%Y-%m-%d")
    filename_base = if agent_name && !agent_name.empty?
                      "#{agent_name}-#{date_str}"
                    else
                      "one_time_pad-#{date_str}"
                    end
    
    # Ensure uniqueness: if file exists, add a counter
    filename = File.join(path, "#{filename_base}.json")
    counter = 1
    while File.exist?(filename)
      filename = File.join(path, "#{filename_base}-#{counter.to_s.rjust(3, '0')}.json")
      counter += 1
      # Safety check to prevent infinite loop
      raise StandardError, "Too many pad files with same date prefix: #{filename_base}" if counter > 999
    end
    
    # Generate a unique pad_id for internal use (using epoch timestamp + random)
    pad_id = generate_pad_id

    pads = generate_pads(num.to_i, len)
    pad_data = {
      id: pad_id,
      pads: pads
    }

    File.write(filename, pad_data.to_json)
    NumberStation.log.debug "Created one-time pad: #{filename}"
    filename
  end

  private

  def self.round_up_to_multiple_of_5(number)
    # Round up to nearest multiple of 5
    # Examples: 3 -> 5, 7 -> 10, 12 -> 15, 15 -> 15, 500 -> 500
    ((number + 4) / 5) * 5
  end

  def self.generate_pad_id
    # Generate a unique ID using epoch timestamp and random component
    # This ensures uniqueness even if multiple pads are created in the same second
    "#{Time.now.to_i}-#{rand(1000..9999)}"
  end

  def self.generate_pads(num_pads, length)
    pads = {}
    0.upto(num_pads - 1) do |i|
      pads[i] = {
        "key" => SecureRandom.hex(length),
        "epoch_date" => nil,
        "consumed" => false
      }
    end
    pads
  end
end