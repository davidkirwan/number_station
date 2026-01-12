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
require "json"

module NumberStation
  def self.decrypt_message(message, pad_path, pad_num, message_file_path = nil)
    # Strip whitespace and newlines to handle formatted input (groups of 5)
    cleaned_message = message.gsub(/[\s\n\r]/, '')
    NumberStation.log.debug "original message length: #{message.size}, cleaned length: #{cleaned_message.size}"
    
    pad_data = load_pad_data(pad_path)
    pad_key = pad_data["pads"][pad_num]["key"]
    
    validate_message_length(cleaned_message.size, pad_key.size)

    message_bytes = hex_string_to_bytes(cleaned_message)
    pad_bytes = hex_string_to_bytes(pad_key)
    decrypted_bytes = xor_decrypt(message_bytes, pad_bytes)
    decrypted_string = bytes_to_string(decrypted_bytes)

    # Extract encrypted filename if message_file_path is provided
    encrypted_filename = message_file_path ? File.basename(message_file_path) : nil
    write_decrypted_file(pad_data["id"], pad_num, decrypted_string, encrypted_filename)
    decrypted_string
  end

  private

  def self.load_pad_data(pad_path)
    JSON.parse(File.read(pad_path))
  rescue StandardError => e
    NumberStation.log.error "Failed to load pad file: #{e.message}"
    raise
  end

  def self.validate_message_length(message_size, pad_size)
    if message_size > pad_size
      NumberStation.log.error "Message length (#{message_size}) is greater than pad length (#{pad_size}). Unable to continue decryption."
      raise ArgumentError, "Message too long for pad"
    end
    NumberStation.log.debug "message length less than pad length: #{message_size <= pad_size}"
  end

  def self.hex_string_to_bytes(hex_string)
    hex_string.scan(/.{2}/).map { |pair| pair.to_i(16) }
  end

  def self.xor_decrypt(message_bytes, pad_bytes)
    message_bytes.map.with_index { |byte, index| byte ^ pad_bytes[index] }
  end

  def self.bytes_to_string(bytes)
    bytes.pack('U*').force_encoding('utf-8')
  end

  def self.write_decrypted_file(pad_id, pad_num, decrypted_content, encrypted_filename = nil)
    # Only write to file if decrypting from a file (not from string)
    unless encrypted_filename
      NumberStation.log.debug "Decrypted message (not saving to file)"
      return
    end
    
    # Try to extract agent name and pad info from encrypted filename if provided
    if encrypted_filename && !encrypted_filename.empty?
      # Parse encrypted filename format: agentname_name-of-the-pad-file_padnumber_encrypted.txt
      # Example: Abyss_Abyss-2026-01-12-001_pad2_encrypted.txt
      if encrypted_filename.match(/^(.+?)_(.+?)_pad(\d+)_encrypted\.txt$/)
        agent_name = $1
        pad_filename = $2
        pad_num_from_filename = $3
        
        # Use the same format but with _decrypted.txt
        filename = "#{agent_name}_#{pad_filename}_pad#{pad_num_from_filename}_decrypted.txt"
        NumberStation.log.info "Writing decrypted message to file #{filename}"
        File.write(filename, decrypted_content)
        return
      end
    end
    
    # Fallback: extract agent name from pad_path if available
    # For now, use pad_id and pad_num as fallback
    filename = "#{pad_id}_pad#{pad_num}_decrypted.txt"
    
    NumberStation.log.info "Writing decrypted message to file #{filename}"
    File.write(filename, decrypted_content)
  rescue StandardError => e
    NumberStation.log.error "Failed to write decrypted file: #{e.message}"
    raise
  end
end
