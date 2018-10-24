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
    puts message
    message = message || "This is a secret message"
    NumberStation.log.debug "message length: #{message.size}"
    message_byte_array = message.unpack('U*')
    #NumberStation.log.debug "#{message_byte_array.inspect}"

    begin
      pad_data = JSON.parse(File.read(pad_path))
    rescue Exception => e
      raise e
    end

    #crypto_hex_str = SecureRandom.hex(message.size)
    crypto_hex_str = pad_data["pads"][pad_num]

    NumberStation.log.debug "message length less than pad length: #{message.size <= crypto_hex_str.size}"

    #puts crypto_hex_str
    crypto_byte_array = crypto_hex_str.scan(/.{1}/).each_slice(2).map { |f, l| (Integer(f,16) << 4) + Integer(l,16) }
    #puts crypto_byte_array.inspect

    encrypted_byte_array = []
    message_byte_array.each_with_index do |i, index|
      encrypted_byte_array << (i ^ crypto_byte_array[index])
    end
    puts encrypted_byte_array.inspect
     
    #encrypted_byte_str = encrypted_byte_array.each.map {|i| i.to_s(16)}.join
    encrypted_byte_str = encrypted_byte_array.map { |n| '%02X' % (n & 0xFF) }.join.downcase
    puts encrypted_byte_str
    puts encrypted_byte_array.size
    puts encrypted_byte_str.size

    #encrypted_byte_array_two = encrypted_byte_str.scan(/.{1}/).each_slice(2).map { |f, l| (Integer(f,16) << 4) + Integer(l,16) }

    #decrypted_byte_array = []
    #encrypted_byte_array_two.each_with_index do |i, index|
    #  decrypted_byte_array << (i ^ crypto_byte_array[index])
    #end
    #puts decrypted_byte_array.inspect

    #decrypted_string = decrypted_byte_array.pack('U*').force_encoding('utf-8')
    #puts decrypted_string

    #puts message == decrypted_string

    return encrypted_byte_str
  end

end