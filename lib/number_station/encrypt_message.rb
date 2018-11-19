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
  
  def self.encrypt_message(message, pad_path, pad_num)
    NumberStation.log.debug "message length: #{message.size}"
    message_byte_array = message.unpack('U*')

    begin
      pad_data = JSON.parse(File.read(pad_path))
    rescue Exception => e
      raise e
    end

    unless pad_data["pads"][pad_num]["consumed"]
      crypto_hex_str = pad_data["pads"][pad_num]["key"]
      NumberStation.log.debug "Marking key as consumed"
      pad_data["pads"][pad_num]["epoch_date"] = Time.now.to_i
      pad_data["pads"][pad_num]["consumed"] = true
      f = File.open(pad_path, "w")
      f.write(pad_data.to_json)
      f.close
    else
       msg = "Warning pad #{pad_num} has been consumed on #{Time.at(pad_data["pads"][pad_num]["epoch_date"])}"
       NumberStation.log.error msg
       exit
    end

    NumberStation.log.debug "message length less than pad length: #{message.size <= crypto_hex_str.size}"
    crypto_byte_array = crypto_hex_str.scan(/.{1}/).each_slice(2).map { |f, l| (Integer(f,16) << 4) + Integer(l,16) }

    encrypted_byte_array = []
    message_byte_array.each_with_index do |i, index|
      encrypted_byte_array << (i ^ crypto_byte_array[index])
    end
         
    encrypted_byte_str = encrypted_byte_array.map { |n| '%02X' % (n & 0xFF) }.join.downcase

    begin
      f_name = "#{pad_data["id"]}_#{pad_num}_#{Time.now.to_i}.txt"
      NumberStation.log.info "Writing encrypted message to file #{f_name}"
      f = File.open(f_name, "w")
      f.write(encrypted_byte_str)
      f.close
    rescue Exception => e
      raise e
    end

    return encrypted_byte_str
  end

end