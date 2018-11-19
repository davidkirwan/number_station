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
  
  def self.decrypt_message(message, pad_path, pad_num)
    NumberStation.log.debug "message length: #{message.size}"
    message_byte_array = message.scan(/.{1}/).each_slice(2).map { |f, l| (Integer(f,16) << 4) + Integer(l,16) } 

    begin
      pad_data = JSON.parse(File.read(pad_path))
    rescue Exception => e
      raise e
    end

    crypto_hex_str = pad_data["pads"][pad_num]["key"]
    NumberStation.log.debug "message length less than pad length: #{message.size <= crypto_hex_str.size}"

    crypto_byte_array = crypto_hex_str.scan(/.{1}/).each_slice(2).map { |f, l| (Integer(f,16) << 4) + Integer(l,16) }

    decrypted_byte_array = []
    message_byte_array.each_with_index do |i, index|
      decrypted_byte_array << (i ^ crypto_byte_array[index])
    end

    decrypted_string = decrypted_byte_array.pack('U*').force_encoding('utf-8')

    begin
      f_name = "#{pad_data["id"]}_#{pad_num}_#{Time.now.to_i}_decrypted.txt"
      NumberStation.log.info "Writing decrypted message to file #{f_name}"
      f = File.open(f_name, "w")
      f.write(decrypted_string)
      f.close
    rescue Exception => e
      raise e
    end
    return decrypted_string
  end

end