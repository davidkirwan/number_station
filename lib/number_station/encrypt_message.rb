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
  def self.encrypt_message(message, pad_path, pad_num, message_file_path = nil)
    NumberStation.log.debug "message length: #{message.size}"
    
    pad_data = load_pad_data(pad_path)
    pad_key = pad_data["pads"][pad_num]["key"]
    
    validate_message_length(message.size, pad_key.size)
    mark_pad_as_consumed(pad_data, pad_path, pad_num)

    message_bytes = message.unpack('U*')
    pad_bytes = hex_string_to_bytes(pad_key)
    encrypted_bytes = xor_encrypt(message_bytes, pad_bytes)
    encrypted_hex = bytes_to_hex_string(encrypted_bytes)
    formatted_hex = format_hex_in_groups(encrypted_hex, 5)

    write_encrypted_file(pad_path, pad_num, formatted_hex, message_file_path)
    formatted_hex
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
      NumberStation.log.error "Message length (#{message_size}) is larger than pad length (#{pad_size}). Break the message into smaller parts."
      raise ArgumentError, "Message too long for pad"
    end
    NumberStation.log.debug "message length less than pad length"
  end

  def self.mark_pad_as_consumed(pad_data, pad_path, pad_num)
    pad = pad_data["pads"][pad_num]
    
    if pad["consumed"]
      consumed_date = Time.at(pad["epoch_date"])
      error_msg = "Pad #{pad_num} has already been consumed on #{consumed_date}"
      NumberStation.log.error error_msg
      raise ArgumentError, error_msg
    end

    NumberStation.log.debug "Marking key as consumed"
    pad["epoch_date"] = Time.now.to_i
    pad["consumed"] = true
    File.write(pad_path, pad_data.to_json)
  end

  def self.hex_string_to_bytes(hex_string)
    hex_string.scan(/.{2}/).map { |pair| pair.to_i(16) }
  end

  def self.xor_encrypt(message_bytes, pad_bytes)
    message_bytes.map.with_index { |byte, index| byte ^ pad_bytes[index] }
  end

  def self.bytes_to_hex_string(bytes)
    bytes.map { |byte| '%02x' % (byte & 0xFF) }.join
  end

  def self.format_hex_in_groups(hex_string, group_size)
    hex_string.scan(/.{1,#{group_size}}/).join(' ')
  end

  def self.write_encrypted_file(pad_path, pad_num, encrypted_content, message_file_path = nil)
    # Extract agent name from pad path if it's in an agent subdirectory
    # Path format: ~/number_station/pads/AGENTNAME/padfile.json
    agent_name = extract_agent_name_from_path(pad_path)
    
    # Extract pad filename without extension
    pad_basename = File.basename(pad_path, ".json")
    
    # Build filename: agentname_name-of-the-pad-file_padnumber_encrypted.txt
    if agent_name && !agent_name.empty?
      filename = "#{agent_name}_#{pad_basename}_pad#{pad_num}_encrypted.txt"
    else
      # Fallback if no agent name found
      filename = "#{pad_basename}_pad#{pad_num}_encrypted.txt"
    end
    
    # Write to file if:
    # 1. Encrypting from a file (message_file_path is actual file path), OR
    # 2. Encrypting from string but agent was specified (message_file_path is "string_input")
    if message_file_path
      NumberStation.log.info "Writing encrypted message to file #{filename}"
      File.write(filename, encrypted_content)
    else
      NumberStation.log.debug "Encrypted message (not saving to file): #{filename}"
    end
  rescue StandardError => e
    NumberStation.log.error "Failed to write encrypted file: #{e.message}"
    raise
  end

  def self.extract_agent_name_from_path(pad_path)
    # Extract agent name from path like: ~/number_station/pads/AGENTNAME/padfile.json
    # or: /path/to/pads/AGENTNAME/padfile.json
    normalized_path = File.expand_path(pad_path)
    pads_dir = File.expand_path(File.join(Dir.home, "number_station", "pads"))
    
    # Check if pad is in a subdirectory of pads directory
    if normalized_path.start_with?(pads_dir + File::SEPARATOR)
      relative_path = normalized_path.sub(pads_dir + File::SEPARATOR, "")
      path_parts = relative_path.split(File::SEPARATOR)
      
      # If path has multiple parts, first part is likely agent name
      if path_parts.length > 1
        agent_name = path_parts.first
        # Verify it's not just the pad filename (should be a directory)
        return agent_name if File.directory?(File.join(pads_dir, agent_name))
      end
    end
    
    # Try to extract from filename if it starts with agent name pattern
    # Format: agentname-YYYY-MM-DD.json
    pad_basename = File.basename(pad_path, ".json")
    if pad_basename.match?(/^([\w-]+)-\d{4}-\d{2}-\d{2}(-\d{3})?$/)
      return $1
    end
    
    nil
  end
end
