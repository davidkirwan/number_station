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
  def self.examine_pads(pads_directory = nil)
    pads_dir = pads_directory || File.join(Dir.home, "number_station", "pads")
    
    unless Dir.exist?(pads_dir)
      NumberStation.log.warn "Pads directory does not exist: #{pads_dir}"
      return []
    end

    # Look for pad files in various formats:
    # - Old format: one_time_pad_XXXXX.json (random number)
    # - New format: agentname-YYYY-MM-DD.json or one_time_pad-YYYY-MM-DD.json (date-based)
    # - New format with counter: agentname-YYYY-MM-DD-001.json
    pad_files = Dir.glob(File.join(pads_dir, "*.json")).select do |file|
      basename = File.basename(file)
      # Match old format: one_time_pad_XXXXX.json
      # Match new format: agentname-YYYY-MM-DD.json or one_time_pad-YYYY-MM-DD.json
      # Match new format with counter: agentname-YYYY-MM-DD-001.json
      basename.match?(/^(one_time_pad|[\w-]+)[_-]\d{4}-\d{2}-\d{2}(-\d{3})?\.json$/) ||
      basename.match?(/^one_time_pad_\d+\.json$/) ||
      basename.match?(/^[\w-]+_\d+\.json$/)
    end
    
    if pad_files.empty?
      NumberStation.log.info "No pad files found in #{pads_dir}"
      return []
    end

    pad_files.map { |file| examine_pad_file(file) }
  end

  def self.find_next_available_pad(pads_directory = nil, min_length = nil, require_unconsumed = true, agent_name = nil)
    # Determine pads directory based on agent name
    if agent_name && !agent_name.empty?
      pads_dir = File.join(Dir.home, "number_station", "pads", agent_name)
    else
      pads_dir = pads_directory || File.join(Dir.home, "number_station", "pads")
    end
    
    unless Dir.exist?(pads_dir)
      error_msg = agent_name ? "Agent pad directory does not exist: #{pads_dir}" : "Pads directory does not exist: #{pads_dir}"
      raise ArgumentError, error_msg
    end

    # Look for pad files in various formats:
    # - Old format: one_time_pad_XXXXX.json (random number)
    # - New format: agentname-YYYY-MM-DD.json or one_time_pad-YYYY-MM-DD.json (date-based)
    # - New format with counter: agentname-YYYY-MM-DD-001.json
    pad_files = Dir.glob(File.join(pads_dir, "*.json")).select do |file|
      basename = File.basename(file)
      # Match old format: one_time_pad_XXXXX.json
      # Match new format: agentname-YYYY-MM-DD.json or one_time_pad-YYYY-MM-DD.json
      # Match new format with counter: agentname-YYYY-MM-DD-001.json
      basename.match?(/^(one_time_pad|[\w-]+)[_-]\d{4}-\d{2}-\d{2}(-\d{3})?\.json$/) ||
      basename.match?(/^one_time_pad_\d+\.json$/) ||
      basename.match?(/^[\w-]+_\d+\.json$/)
    end
    
    if pad_files.empty?
      error_msg = agent_name ? "No pad files found for agent '#{agent_name}' in #{pads_dir}" : "No pad files found in #{pads_dir}"
      raise ArgumentError, error_msg
    end

    # Sort pads to find the oldest one
    # For date-based filenames, alphabetical sort works (YYYY-MM-DD format)
    # For old format (random numbers), sort alphabetically still works
    pad_files.sort!
    
    # Find the oldest pad file that has at least one unconsumed pad
    pad_files.each do |file_path|
      pad_data = JSON.parse(File.read(file_path))
      pads_hash = pad_data["pads"]
      
      next if pads_hash.nil? || pads_hash.empty?
      
      # Check if this pad file has any unconsumed pads
      has_unconsumed = pads_hash.values.any? { |pad| !pad["consumed"] }
      next if require_unconsumed && !has_unconsumed
      
      # Find first pad (unconsumed if require_unconsumed is true)
      pads_hash.each do |pad_num_str, pad|
        next if require_unconsumed && pad["consumed"]
        
        # Check if pad is long enough if min_length is specified
        if min_length
          pad_key_length = pad["key"].length / 2  # Convert hex length to byte length
          next if pad_key_length < min_length
        end
        
        return {
          pad_path: file_path,
          pad_num: pad_num_str,
          pad_id: pad_data["id"].to_s
        }
      end
    end
    
    error_msg = require_unconsumed ? "No available (unconsumed) pads found" : "No pads found"
    error_msg += agent_name ? " for agent '#{agent_name}'" : ""
    raise ArgumentError, "#{error_msg} in #{pads_dir}"
  rescue JSON::ParserError => e
    NumberStation.log.error "Failed to parse pad file: #{e.message}"
    raise
  rescue StandardError => e
    NumberStation.log.error "Error finding pad: #{e.message}"
    raise
  end

  def self.examine_pad_file(file_path)
    pad_data = JSON.parse(File.read(file_path))
    filename = File.basename(file_path)
    
    # Pad data structure: { "id" => "...", "pads" => { "0" => {...}, "1" => {...}, ... } }
    pads_hash = pad_data["pads"]
    
    if pads_hash.nil? || pads_hash.empty?
      return {
        filename: filename,
        error: "No pads found in file"
      }
    end
    
    # Get max message length from first pad's key length
    # Key is hex string, so bytes = hex_length / 2
    # Max message length in characters equals pad length in bytes
    first_pad_key = pads_hash.values.first["key"]
    max_message_length = first_pad_key.length / 2
    
    # Count unconsumed pads
    unconsumed_count = pads_hash.values.count { |pad| !pad["consumed"] }
    total_pads = pads_hash.size
    
    {
      filename: filename,
      pad_id: pad_data["id"].to_s,
      max_message_length: max_message_length,
      total_pads: total_pads,
      unconsumed_pads: unconsumed_count,
      consumed_pads: total_pads - unconsumed_count
    }
  rescue StandardError => e
    NumberStation.log.error "Failed to examine pad file #{file_path}: #{e.message}"
    {
      filename: File.basename(file_path),
      error: e.message
    }
  end
end
