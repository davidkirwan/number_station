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

require 'thor'
require 'fileutils'
require 'date'
require 'json'

module NumberStation
  class Pad < Thor
    # Remove the built-in 'tree' command
    def self.all_commands
      super.reject { |k, v| k == 'tree' }
    end

    desc "create [--name NAME --path PATH --numpads NUM --length LENGTH]", "Generate a one time pad of LENGTH containing NUM entries"
    long_desc <<-CREATE_PAD_LONG_DESC
    Generate a one time pad of LENGTH containing NUM entries
    
    Parameters:
      --name NAME - Agent name to associate with this pad. Creates subdirectory ~/number_station/pads/NAME/ if --path is not provided
      --path PATH - Directory where the pad file will be created (defaults to current directory, or ~/number_station/pads/NAME/ if --name is provided)
      --numpads NUM - Number of pads to generate (defaults to 500)
      --length LENGTH - Length of each pad in characters (defaults to 500)

    If no parameters are passed it will generate 500 one time pads in the current
    directory of size 500 characters.
    
    If --name is provided without --path, the pad will be created in ~/number_station/pads/NAME/
    
    Examples:
      number_station pad create --name Shadow --numpads 1000 --length 1000
      number_station pad create --name Shadow
      number_station pad create --path ~/number_station/pads --numpads 10 --length 500
      number_station pad create
    CREATE_PAD_LONG_DESC
    option :name, type: :string
    option :length, type: :numeric
    option :numpads, type: :numeric
    option :path, type: :string
    def create
      ensure_config_loaded
      
      # Determine the pad directory and agent name
      pad_path = options[:path]
      agent_name = options[:name]
      
      if pad_path.nil? && agent_name
        # If name is provided but no path, create agent-specific directory
        pad_path = File.join(Dir.home, "number_station", "pads", agent_name)
        FileUtils.mkdir_p(pad_path)
        NumberStation.log.info "Created pad directory for agent: #{pad_path}"
      end
      
      # Pass options (make_otp will use defaults: 500 pads, 500 characters if nil)
      # Also pass agent_name so it can be used in the filename
      NumberStation.make_otp(pad_path, options[:length], options[:numpads], agent_name)
    end

    desc "stats [--path PATH]", "Show statistics about one-time pads"
    long_desc <<-PAD_STATS_LONG_DESC
    Lists all one-time pad files in the pads directory (default: ~/number_station/pads),
    including pads in subdirectories. Pads are grouped by agent name (subdirectory name).
    
    For each pad file, shows:
      - Pad filename
      - Maximum message length (in characters) that can be encrypted
      - Number of unconsumed pads remaining
    
    Optional parameters:
      --path PATH  Specify a custom directory path to examine pads from
    
    Examples:
      number_station pad stats
      number_station pad stats --path ~/custom/pads
    PAD_STATS_LONG_DESC
    option :path, type: :string
    def stats
      ensure_config_loaded
      
      pads_dir = options[:path] || File.join(Dir.home, "number_station", "pads")
      
      unless Dir.exist?(pads_dir)
        puts "Pads directory does not exist: #{pads_dir}"
        return
      end
      
      # Find all pad files recursively in various formats:
      # - Old format: one_time_pad_XXXXX.json (random number)
      # - New format: agentname-YYYY-MM-DD.json or one_time_pad-YYYY-MM-DD.json (date-based)
      # - New format with counter: agentname-YYYY-MM-DD-001.json
      pad_files = Dir.glob(File.join(pads_dir, "**", "*.json")).select do |file|
        basename = File.basename(file)
        # Match old format: one_time_pad_XXXXX.json
        # Match new format: agentname-YYYY-MM-DD.json or one_time_pad-YYYY-MM-DD.json
        # Match new format with counter: agentname-YYYY-MM-DD-001.json
        basename.match?(/^(one_time_pad|[\w-]+)[_-]\d{4}-\d{2}-\d{2}(-\d{3})?\.json$/) ||
        basename.match?(/^one_time_pad_\d+\.json$/) ||
        basename.match?(/^[\w-]+_\d+\.json$/)
      end
      
      if pad_files.empty?
        puts "No pad files found in #{pads_dir}"
        return
      end
      
      # Group pads by their parent directory (agent name)
      pads_by_agent = {}
      
      pad_files.each do |file_path|
        # Get relative path from pads_dir
        relative_path = file_path.sub(/^#{Regexp.escape(pads_dir)}\/?/, '')
        dir_parts = File.dirname(relative_path).split(File::SEPARATOR)
        
        # Determine agent name: if in subdirectory, use subdirectory name; otherwise use "root"
        agent_name = dir_parts.empty? || dir_parts == ['.'] ? "root" : dir_parts.first
        
        pads_by_agent[agent_name] ||= []
        pad_info = NumberStation.examine_pad_file(file_path)
        pad_info[:file_path] = file_path
        pad_info[:agent_name] = agent_name
        pads_by_agent[agent_name] << pad_info
      end
      
      puts "\nOne-Time Pad Statistics"
      puts "=" * 80
      puts "Directory: #{pads_dir}"
      puts "=" * 80
      puts
      
      # Sort agents: root first, then alphabetically
      sorted_agents = pads_by_agent.keys.sort_by { |k| k == "root" ? "" : k }
      
      total_pad_files = 0
      total_unconsumed = 0
      total_pads = 0
      
      sorted_agents.each do |agent_name|
        agent_pads = pads_by_agent[agent_name]
        agent_unconsumed = agent_pads.inject(0) { |sum, info| sum + (info[:unconsumed_pads] || 0) }
        agent_total_pads = agent_pads.inject(0) { |sum, info| sum + (info[:total_pads] || 0) }
        
        # Display agent header
        if agent_name == "root"
          puts "Root Directory:"
        else
          puts "Agent: #{agent_name}"
        end
        puts "-" * 80
        
        # Display each pad for this agent
        agent_pads.each do |info|
          if info[:error]
            puts "  ✗ #{info[:filename]}: ERROR - #{info[:error]}"
          else
            puts "  Pad: #{info[:filename]}"
            puts "    ID: #{info[:pad_id]}"
            puts "    Maximum message length: #{info[:max_message_length]} characters"
            puts "    Total pads: #{info[:total_pads]}"
            puts "    Unconsumed: #{info[:unconsumed_pads]}"
            puts "    Consumed: #{info[:consumed_pads]}"
          end
        end
        
        puts "  Summary: #{agent_pads.size} pad file(s), #{agent_unconsumed} unconsumed pad(s) out of #{agent_total_pads} total"
        puts
        
        total_pad_files += agent_pads.size
        total_unconsumed += agent_unconsumed
        total_pads += agent_total_pads
      end
      
      puts "=" * 80
      puts "Overall Summary: #{total_pad_files} pad file(s), #{total_unconsumed} unconsumed pad(s) out of #{total_pads} total"
      puts "=" * 80
    end

    private

    def ensure_config_loaded
      NumberStation::ConfigReader.read_config unless NumberStation.data
    end
  end

  class Agents < Thor
    # Remove the built-in 'tree' command
    def self.all_commands
      super.reject { |k, v| k == 'tree' }
    end

    # Map hyphenated command names
    map "update-handler" => :update_handler
    map "list-all" => :list_all


    desc "list", "List all active agents in a condensed format"
    long_desc <<-LIST_AGENTS_LONG_DESC
    Shows a condensed list of all active agents with their key information:
      - Name
      - Location
      - Handler Codeword
      - Start Date
    LIST_AGENTS_LONG_DESC
    def list
      ensure_config_loaded
      
      active_agents = NumberStation.active_agents
      
      if active_agents.empty?
        puts "No active agents found."
        return
      end
      
      puts "\nActive Agents (#{active_agents.size})"
      puts "=" * 100
      
      # Print header
      printf "%-20s %-25s %-25s %-15s\n", "Name", "Location", "Handler Codeword", "Start Date"
      puts "-" * 100
      
      # Print each agent
      active_agents.each do |agent|
        name = agent['name'] || 'N/A'
        location = agent['location'] || '-'
        handler = agent['handler_codeword'] || '-'
        start_date = agent['start_date'] || '-'
        
        printf "%-20s %-25s %-25s %-15s\n", name, location, handler, start_date
      end
      
      puts "=" * 100
    end

    desc "list-all", "List all active agents and inactive agents with end dates"
    long_desc <<-LIST_ALL_AGENTS_LONG_DESC
    Shows all active agents and all inactive agents that have an end_date in a condensed format with:
      - Name
      - Status (Active/Inactive)
      - Location
      - Handler Codeword
      - Start Date
      - End Date
    
    Includes:
      - All currently active agents (regardless of end_date)
      - All inactive agents that have an end_date (were active and then deactivated)
    LIST_ALL_AGENTS_LONG_DESC
    def list_all
      ensure_config_loaded
      
      all_agents = NumberStation.agent_list
      
      # Filter to: active agents OR inactive agents with end_date
      filtered_agents = all_agents.select do |a|
        a['active'] == true || (a['end_date'] && !a['end_date'].to_s.empty?)
      end
      
      if filtered_agents.empty?
        puts "No active agents or agents with end dates found."
        return
      end
      
      active_count = filtered_agents.count { |a| a['active'] }
      inactive_count = filtered_agents.size - active_count
      
      puts "\nAll Active Agents and Agents with End Dates (#{filtered_agents.size} total: #{active_count} active, #{inactive_count} inactive)"
      puts "=" * 120
      
      # Print header
      printf "%-20s %-10s %-20s %-25s %-15s %-15s\n", 
             "Name", "Status", "Location", "Handler Codeword", "Start Date", "End Date"
      puts "-" * 120
      
      # Print each agent
      filtered_agents.each do |agent|
        name = agent['name'] || 'N/A'
        status = agent['active'] ? 'Active' : 'Inactive'
        location = agent['location'] || '-'
        handler = agent['handler_codeword'] || '-'
        start_date = agent['start_date'] || '-'
        end_date = agent['end_date'] || '-'
        
        printf "%-20s %-10s %-20s %-25s %-15s %-15s\n", 
               name, status, location, handler, start_date, end_date
      end
      
      puts "=" * 120
    end

    desc "stats", "Display statistics about active agents"
    long_desc <<-AGENT_STATS_LONG_DESC
    Shows statistics and details about all active agents, including:
      - Total number of active agents
      - Agent names and details (location, handler codeword, dates, etc.)
      - Summary statistics
    AGENT_STATS_LONG_DESC
    def stats
      ensure_config_loaded
      
      all_agents = NumberStation.agent_list
      active_agents = NumberStation.active_agents
      inactive_count = all_agents.size - active_agents.size
      
      puts "\nAgent Statistics"
      puts "=" * 80
      puts
      
      # Summary statistics
      puts "Summary:"
      puts "  Total agents: #{all_agents.size}"
      puts "  Active agents: #{active_agents.size}"
      puts "  Inactive agents: #{inactive_count}"
      puts
      
      if active_agents.empty?
        puts "No active agents found."
        puts "=" * 80
        return
      end
      
      puts "Active Agents:"
      puts "-" * 80
      puts
      
      active_agents.each_with_index do |agent, index|
        puts "#{index + 1}. #{agent['name']}"
        puts "   Location: #{agent['location'] || 'Not specified'}"
        puts "   Handler Codeword: #{agent['handler_codeword'] || 'Not specified'}"
        puts "   Start Date: #{agent['start_date'] || 'Not specified'}"
        puts "   End Date: #{agent['end_date'] || 'Not specified'}"
        puts "   Status: Active"
        puts
      end
      
      # Additional statistics
      agents_with_location = active_agents.count { |a| a['location'] && !a['location'].to_s.empty? }
      agents_with_codeword = active_agents.count { |a| a['handler_codeword'] && !a['handler_codeword'].to_s.empty? }
      agents_with_start_date = active_agents.count { |a| a['start_date'] && !a['start_date'].to_s.empty? }
      agents_with_end_date = active_agents.count { |a| a['end_date'] && !a['end_date'].to_s.empty? }
      
      puts "-" * 80
      puts "Additional Statistics:"
      puts "  Agents with location: #{agents_with_location}/#{active_agents.size}"
      puts "  Agents with handler codeword: #{agents_with_codeword}/#{active_agents.size}"
      puts "  Agents with start date: #{agents_with_start_date}/#{active_agents.size}"
      puts "  Agents with end date: #{agents_with_end_date}/#{active_agents.size}"
      puts "=" * 80
    end

    desc "create NAME", "Create a new agent"
    long_desc <<-CREATE_AGENT_LONG_DESC
    Create a new agent with the specified name. Optionally set location and handler codeword.
    
    Parameters:
      NAME - The agent name (required)
    
    Options:
      --location LOCATION - Set the agent's location
      --handler HANDLER - Set the handler codeword
    
    Examples:
      number_station agents create Shadow --location "Berlin" --handler "NIGHTFALL"
      number_station agents create Ghost --location "Moscow"
      number_station agents create Phantom
    CREATE_AGENT_LONG_DESC
    option :location, type: :string
    option :handler, type: :string
    def create(name = nil)
      if name.nil? || name.empty?
        help("create")
        return
      end
      
      ensure_config_loaded
      
      # Check if agent already exists
      if NumberStation.find_agent_by_name(name)
        raise Thor::Error, "Agent '#{name}' already exists"
      end
      
      # Create new agent
      new_agent = {
        "name" => name,
        "location" => options[:location],
        "handler_codeword" => options[:handler],
        "start_date" => nil,
        "end_date" => nil,
        "active" => false
      }
      
      # Add to agent list
      config_data = NumberStation.data.dup
      config_data["agent_list"] ||= []
      config_data["agent_list"] << new_agent
      
      # Save config
      NumberStation::ConfigReader.save_config(config_data)
      puts "Created agent: #{name}"
      puts "  Location: #{options[:location] || 'Not specified'}"
      puts "  Handler Codeword: #{options[:handler] || 'Not specified'}"
    end

    desc "activate NAME", "Activate an agent"
    long_desc <<-ACTIVATE_AGENT_LONG_DESC
    Activate an agent by name. Sets active status to true and optionally sets start_date.
    
    Parameters:
      NAME - The agent name (required)
    
    Options:
      --start-date DATE - Set the start date (defaults to today if not specified)
    
    Examples:
      number_station agents activate Shadow
      number_station agents activate Shadow --start-date "2024-01-15"
    ACTIVATE_AGENT_LONG_DESC
    option :start_date, type: :string
    def activate(name = nil)
      if name.nil? || name.empty?
        help("activate")
        return
      end
      
      ensure_config_loaded
      
      agent = NumberStation.find_agent_by_name(name)
      unless agent
        raise Thor::Error, "Agent '#{name}' not found"
      end
      
      if agent["active"]
        puts "Agent '#{name}' is already active"
        return
      end
      
      # Update agent
      config_data = NumberStation.data.dup
      agent_index = config_data["agent_list"].index { |a| a["name"] == name }
      
      config_data["agent_list"][agent_index]["active"] = true
      config_data["agent_list"][agent_index]["start_date"] = options[:start_date] || Date.today.to_s
      config_data["agent_list"][agent_index]["end_date"] = nil  # Reset end_date when reactivating
      
      # Save config
      NumberStation::ConfigReader.save_config(config_data)
      puts "Activated agent: #{name}"
      puts "  Start Date: #{config_data["agent_list"][agent_index]["start_date"]}"
    end

    desc "deactivate NAME", "Deactivate an agent"
    long_desc <<-DEACTIVATE_AGENT_LONG_DESC
    Deactivate an agent by name. Sets active status to false and optionally sets end_date.
    
    Parameters:
      NAME - The agent name (required)
    
    Options:
      --end-date DATE - Set the end date (defaults to today if not specified)
    
    Examples:
      number_station agents deactivate Shadow
      number_station agents deactivate Shadow --end-date "2024-12-31"
    DEACTIVATE_AGENT_LONG_DESC
    option :end_date, type: :string
    def deactivate(name = nil)
      if name.nil? || name.empty?
        help("deactivate")
        return
      end
      
      ensure_config_loaded
      
      agent = NumberStation.find_agent_by_name(name)
      unless agent
        raise Thor::Error, "Agent '#{name}' not found"
      end
      
      unless agent["active"]
        puts "Agent '#{name}' is already inactive"
        return
      end
      
      # Update agent
      config_data = NumberStation.data.dup
      agent_index = config_data["agent_list"].index { |a| a["name"] == name }
      
      config_data["agent_list"][agent_index]["active"] = false
      config_data["agent_list"][agent_index]["end_date"] = options[:end_date] || Date.today.to_s
      
      # Save config
      NumberStation::ConfigReader.save_config(config_data)
      puts "Deactivated agent: #{name}"
      puts "  End Date: #{config_data["agent_list"][agent_index]["end_date"]}"
    end

    desc "update_handler NAME HANDLER", "Update the handler codeword for an agent"
    long_desc <<-UPDATE_HANDLER_LONG_DESC
    Update the handler codeword for an agent.
    
    Parameters:
      NAME - The agent name (required)
      HANDLER - The new handler codeword (required)
    
    Examples:
      number_station agents update-handler Shadow DAWNBREAK
      number_station agents update-handler Ghost NEWCODE123
    UPDATE_HANDLER_LONG_DESC
    def update_handler(name = nil, handler = nil)
      if name.nil? || name.empty? || handler.nil? || handler.empty?
        help("update_handler")
        return
      end
      
      ensure_config_loaded
      
      agent = NumberStation.find_agent_by_name(name)
      unless agent
        raise Thor::Error, "Agent '#{name}' not found"
      end
      
      # Update agent
      config_data = NumberStation.data.dup
      agent_index = config_data["agent_list"].index { |a| a["name"] == name }
      
      old_handler = config_data["agent_list"][agent_index]["handler_codeword"]
      config_data["agent_list"][agent_index]["handler_codeword"] = handler
      
      # Save config
      NumberStation::ConfigReader.save_config(config_data)
      puts "Updated handler codeword for agent: #{name}"
      puts "  Old handler: #{old_handler || 'Not specified'}"
      puts "  New handler: #{handler}"
    end

    private

    def ensure_config_loaded
      NumberStation::ConfigReader.read_config unless NumberStation.data
    end
  end

  class CLI < Thor
    desc "create_config [--path PATH]", "create the config file conf.yaml"
    long_desc <<-CREATE_CONFIG_LONG_DESC
      `create_config` will copy the sample config from resources/conf.yaml to ~/number_station/conf.yaml.
      If the optional parameter `--path PATH` is passed then the config file is created at PATH/conf.yaml.
    CREATE_CONFIG_LONG_DESC
    option :path, type: :string
    def create_config
      ensure_config_loaded

      target_path = options[:path] || File.join(Dir.home, "number_station")
      FileUtils.mkdir_p(target_path)

      target_file = File.join(target_path, "conf.yaml")
      
      # Find the source config file - try multiple locations
      source_file = find_config_template
      
      unless File.exist?(target_file)
        if source_file && File.exist?(source_file)
          FileUtils.cp(source_file, target_file)
          NumberStation.log.info "Created config file: #{target_file}"
        else
          # If template not found, create a default config
          create_default_config(target_file)
          NumberStation.log.info "Created default config file: #{target_file}"
        end
      else
        NumberStation.log.info "Config file already exists: #{target_file}"
      end

      # Copy message template files (intro, outro, repeat) to target directory
      copy_message_template_files(target_path)
      
      NumberStation::ConfigReader.read_config
      NumberStation.log.debug "create_config completed"
    end


    desc "convert_to_phonetic [MESSAGE_PATH]", "Convert a message to phonetic output."
    long_desc <<-CONVERT_MESSAGE_LONG_DESC
      convert_message takes a parameter which should point to a text file containing a message.
        MESSAGE_PATH\n
      Optional parameters:\n
        --intro [INTRO_PATH] should be a text file containing intro message. Overrides value in conf.yaml\n
        --outro [OUTRO_PATH] should be a text file containing the outro message. Overrides value in conf.yaml\n
        --repeat [REPEAT_PATH] should be a text file containing repeat message. Included after first message.\n
        --mp3 [MP3] output message as an mp3 file.

      Final message will be created from: intro (as-is) + message (phonetic) + repeat (as-is) + message (phonetic again) + outro (as-is)
    CONVERT_MESSAGE_LONG_DESC
    option :intro, type: :string
    option :outro, type: :string
    option :repeat, type: :string
    option :mp3, type: :string
    def convert_to_phonetic(message_path)
      ensure_config_loaded

      # Load intro, outro, and repeat as-is (not converted to phonetic)
      intro = load_message_component(:intro, options[:intro])
      outro = load_message_component(:outro, options[:outro])
      repeat = load_message_component(:repeat, options[:repeat])
      
      # Convert message to phonetic
      message = NumberStation.to_phonetic(message_path)

      # Build output: intro (as-is) + message (phonetic) + repeat (as-is) + message (phonetic again) + outro (as-is)
      output_parts = []
      output_parts << intro.strip if intro && !intro.strip.empty?
      output_parts << message.strip if message && !message.strip.empty?
      output_parts << repeat.strip if repeat && !repeat.strip.empty?
      output_parts << message.strip if message && !message.strip.empty?  # Repeat the message
      output_parts << outro.strip if outro && !outro.strip.empty?
      
      # Join with newlines between components for readability
      # Strip each part to remove trailing newlines that might cause extra blank lines
      output = output_parts.join("\n")
      NumberStation.log.info "output: #{output}"

      # Generate output filename based on input filename
      input_basename = File.basename(message_path, File.extname(message_path))
      output_filename = "#{input_basename}_phonetic.txt"
      output_path = File.join(File.dirname(message_path), output_filename)
      
      # Save output to file
      File.write(output_path, output)
      NumberStation.log.info "Saved phonetic output to: #{output_path}"

      if options[:mp3]
        NumberStation.log.debug "Generating mp3 output: #{options[:mp3]}"
        NumberStation.write_mp3(output, options[:mp3])
      end

      output
    end

    desc "convert_to_espeak FILE", "Convert a phonetic message file to GLaDOS-style espeak XML"
    long_desc <<-CONVERT_TO_ESPEAK_LONG_DESC
    Convert a phonetic message file (typically generated by convert_to_phonetic) to GLaDOS-style espeak XML format.
    
    Parameters:
      FILE - Path to phonetic message file (e.g., Abyss_Abyss-2026-01-12-001_pad2_encrypted_phonetic.txt)
    
    The output XML file will be saved with the same name as the input file, but with .xml extension.
    
    Example:
      number_station convert_to_espeak Abyss_Abyss-2026-01-12-001_pad2_encrypted_phonetic.txt
      # Creates: Abyss_Abyss-2026-01-12-001_pad2_encrypted_phonetic.xml
    CONVERT_TO_ESPEAK_LONG_DESC
    def convert_to_espeak(file)
      ensure_config_loaded
      
      unless File.exist?(file)
        raise Thor::Error, "File not found: #{file}"
      end
      
      output_path = NumberStation.generate_glados_espeak(file)
      puts "Generated GLaDOS espeak XML: #{output_path}"
    end

    desc "convert_pad_to_asciidoc --padpath PADPATH", "Convert a pad file to AsciiDoc format"
    long_desc <<-CONVERT_PAD_TO_ASCIIDOC_LONG_DESC
    Convert a one-time pad file to AsciiDoc format with each pad as a chapter.
    
    Parameters:
      --padpath PADPATH - Path to pad file (e.g., ~/number_station/pads/Shadow/Shadow-2026-01-12.json)
    
    Each pad in the file is converted to groups of 5 characters, separated by spaces.
    Output saved as FILENAME.asciidoc in the same directory.
    
    Example:
      number_station convert_pad_to_asciidoc --padpath ~/number_station/pads/Shadow/Shadow-2026-01-12.json
    CONVERT_PAD_TO_ASCIIDOC_LONG_DESC
    option :padpath, type: :string, required: true
    def convert_pad_to_asciidoc
      ensure_config_loaded
      
      pad_path = options[:padpath]
      unless File.exist?(pad_path)
        raise Thor::Error, "Pad file not found: #{pad_path}"
      end
      
      # Read pad file
      pad_data = JSON.parse(File.read(pad_path))
      pad_id = pad_data["id"]
      pads_hash = pad_data["pads"]
      
      if pads_hash.nil? || pads_hash.empty?
        raise Thor::Error, "No pads found in file: #{pad_path}"
      end
      
      # Generate output filename: replace .json extension with .asciidoc
      input_basename = File.basename(pad_path, File.extname(pad_path))
      output_filename = "#{input_basename}.asciidoc"
      output_path = File.join(File.dirname(pad_path), output_filename)
      
      # Build AsciiDoc content
      asciidoc_content = []
      asciidoc_content << "= One-Time Pad: #{input_basename}"
      asciidoc_content << ""
      
      # Process each pad
      pads_hash.sort_by { |k, v| k.to_i }.each do |pad_num, pad_info|
        hex_key = pad_info["key"]
        
        # Convert hex string to groups of 5 characters, separated by spaces
        # Remove any existing formatting and group by 5
        cleaned_hex = hex_key.gsub(/[\s\n\r]/, '')
        grouped_hex = cleaned_hex.chars.each_slice(5).map(&:join).join(' ')
        
        # Add chapter heading for this pad
        asciidoc_content << "== Pad #{pad_num}"
        asciidoc_content << ""
        asciidoc_content << "[source]"
        asciidoc_content << "----"
        asciidoc_content << grouped_hex
        asciidoc_content << "----"
        asciidoc_content << ""
        
        # Add page break after every 2nd pad (after pad 1, 3, 5, etc.)
        if pad_num.to_i % 2 == 1
          asciidoc_content << "<<<"
          asciidoc_content << ""
        end
      end
      
      # Write AsciiDoc file
      File.write(output_path, asciidoc_content.join("\n"))
      puts "Generated AsciiDoc file: #{output_path}"
    end

    desc "convert_to_pdf ASCIIDOC_FILE", "Convert an AsciiDoc file to PDF using asciidoctor-pdf"
    long_desc <<-CONVERT_TO_PDF_LONG_DESC
    Convert an AsciiDoc file (typically generated by convert_pad_to_asciidoc) to PDF format.
    
    Parameters:
      ASCIIDOC_FILE - Path to AsciiDoc file (e.g., Shadow-2026-01-12.asciidoc)
    
    The command checks if asciidoctor-pdf is available before executing.
    Output saved as FILENAME.pdf in the same directory.
    
    Example:
      number_station convert_to_pdf Shadow-2026-01-12.asciidoc
    CONVERT_TO_PDF_LONG_DESC
    def convert_to_pdf(asciidoc_file)
      ensure_config_loaded
      
      unless File.exist?(asciidoc_file)
        raise Thor::Error, "File not found: #{asciidoc_file}"
      end
      
      # Check if asciidoctor-pdf is available
      # Check if command exists first (most reliable)
      unless NumberStation.command?('asciidoctor-pdf')
        raise Thor::Error, "asciidoctor-pdf is not available. Please install it with: gem install asciidoctor-pdf"
      end
      
      # Generate output filename: replace .asciidoc extension with .pdf
      input_basename = File.basename(asciidoc_file, File.extname(asciidoc_file))
      output_filename = "#{input_basename}.pdf"
      output_path = File.join(File.dirname(asciidoc_file), output_filename)
      
      # Convert using asciidoctor-pdf command
      cmd = "asciidoctor-pdf #{asciidoc_file} -o #{output_path}"
      NumberStation.log.info "Running: #{cmd}"
      system(cmd)
      
      unless $?.success?
        raise Thor::Error, "PDF conversion failed with exit code #{$?.exitstatus}"
      end
      
      puts "Generated PDF file: #{output_path}"
    end

    desc "espeak XML_FILE", "Use espeak to read an XML file"
    long_desc <<-ESPEAK_LONG_DESC
    Use the espeak utility to read an XML file with GLaDOS-style voice settings.
    
    Parameters:
      XML_FILE - Path to XML file (typically generated by convert_to_espeak)
    
    The command checks if espeak is available on the system before executing.
    Uses GLaDOS voice settings: -ven+f3 -m -p 60 -s 100 -g 4
    
    Example:
      number_station espeak Abyss_Abyss-2026-01-12-001_pad2_encrypted_phonetic.xml
    ESPEAK_LONG_DESC
    def espeak(xml_file)
      ensure_config_loaded
      
      # Check if espeak is available
      unless NumberStation.command?('espeak')
        raise Thor::Error, "espeak utility is not available on this system. Please install espeak to use this command."
      end
      
      unless File.exist?(xml_file)
        raise Thor::Error, "File not found: #{xml_file}"
      end
      
      # Call espeak with GLaDOS voice settings
      cmd = "espeak -ven+f3 -m -p 60 -s 100 -g 4 -f #{xml_file}"
      NumberStation.log.info "Running espeak: #{cmd}"
      system(cmd)
      
      unless $?.success?
        raise Thor::Error, "espeak command failed with exit code #{$?.exitstatus}"
      end
    end

    desc "convert_to_mp3 XML_FILE", "Convert an XML file to MP3 using espeak and ffmpeg"
    long_desc <<-CONVERT_TO_MP3_LONG_DESC
    Convert an XML file (typically generated by convert_to_espeak) to MP3 audio format.
    
    Parameters:
      XML_FILE - Path to XML file (e.g., Abyss_Abyss-2026-01-12-001_pad2_encrypted_phonetic.xml)
    
    The command checks if both espeak and ffmpeg utilities are available before executing.
    The output MP3 file will be saved with the same name as the input file, but with .mp3 extension.
    
    Example:
      number_station convert_to_mp3 Abyss_Abyss-2026-01-12-001_pad2_encrypted_phonetic.xml
      # Creates: Abyss_Abyss-2026-01-12-001_pad2_encrypted_phonetic.mp3
    CONVERT_TO_MP3_LONG_DESC
    def convert_to_mp3(xml_file)
      ensure_config_loaded
      
      # Check if espeak and ffmpeg are available
      unless NumberStation.command?('espeak')
        raise Thor::Error, "espeak utility is not available on this system. Please install espeak to use this command."
      end
      
      unless NumberStation.command?('ffmpeg')
        raise Thor::Error, "ffmpeg utility is not available on this system. Please install ffmpeg to use this command."
      end
      
      unless File.exist?(xml_file)
        raise Thor::Error, "File not found: #{xml_file}"
      end
      
      # Generate output filename: replace .xml extension with .mp3
      input_basename = File.basename(xml_file, File.extname(xml_file))
      output_filename = "#{input_basename}.mp3"
      output_path = File.join(File.dirname(xml_file), output_filename)
      
      # Call espeak piped to ffmpeg
      cmd = "espeak -ven+f3 -m -p 60 -s 100 -g 4 -f #{xml_file} --stdout | ffmpeg -i - -ar 44100 -ac 2 -ab 192k -f mp3 #{output_path}"
      NumberStation.log.info "Running: #{cmd}"
      system(cmd)
      
      unless $?.success?
        raise Thor::Error, "convert_to_mp3 command failed with exit code #{$?.exitstatus}"
      end
      
      puts "Generated MP3 file: #{output_path}"
    end


    desc "encrypt [MESSAGE --file FILE --agent AGENT --numpad NUMPAD --padpath PADPATH]", "Encrypt a message using the key: NUMPAD in one time pad PADPATH"
    long_desc <<-ENCRYPT_MESSAGE_LONG_DESC
    Encrypt a message using key NUMPAD in one-time-pad PADPATH
    
    Parameters:
      MESSAGE - Message string to encrypt (if --file is not provided)
      --file FILE - Path to message file (alternative to passing message as argument)
      --agent AGENT - Agent name. If provided, searches for oldest pad in ~/number_station/pads/AGENT/
      --numpad NUMPAD - Pad number (optional, will try to auto-detect if not provided)
      --padpath PADPATH - Path to pad file (optional, will try to auto-detect if not provided)

    If --agent is provided, the system will search for the oldest pad with unconsumed pads
    in the agent-specific directory (~/number_station/pads/AGENT/).
    
    If --agent is not provided and --padpath/--numpad are not specified, the system will
    search for the oldest pad with unconsumed pads in ~/number_station/pads/.
    
    Examples:
      number_station encrypt "Hello World" --agent Shadow
      number_station encrypt --file message.txt --agent Shadow
      number_station encrypt "Hello World" --agent Shadow --numpad 5
      number_station encrypt --file message.txt --padpath ~/number_station/pads/Shadow/Shadow-2024-01-15.json --numpad 10
    ENCRYPT_MESSAGE_LONG_DESC
    option :file, type: :string
    option :agent, type: :string
    option :numpad, type: :string
    option :padpath, type: :string
    def encrypt(message = nil)
      # Handle help request
      if message == "help" || (message.nil? && options[:file].nil? && options[:agent].nil?)
        help("encrypt")
        return
      end
      
      ensure_config_loaded
      
      # Validate agent if provided
      if options[:agent]
        agent = NumberStation.find_agent_by_name(options[:agent])
        unless agent
          raise Thor::Error, "Agent '#{options[:agent]}' not found"
        end
        unless agent["active"] == true
          raise Thor::Error, "Agent '#{options[:agent]}' is inactive. Messages can only be encrypted for active agents."
        end
      end
      
      # Determine message content: from --file option or from argument
      if options[:file]
        unless File.exist?(options[:file])
          raise Thor::Error, "File not found: #{options[:file]}"
        end
        message_data = File.read(options[:file])
        message_file_path = options[:file]  # Store for filename generation
      elsif message && !message.empty?
        message_data = message
        # If agent is specified, we'll save to file (even though input is string)
        # Pass a flag to indicate we should save to file
        message_file_path = options[:agent] ? "string_input" : nil
      else
        raise Thor::Error, "Either provide a message string as argument or use --file option"
      end
      
      # Auto-detect pad if not provided
      if options[:padpath].nil? || options[:numpad].nil?
        agent_name = options[:agent]
        pad_info = NumberStation.find_next_available_pad(nil, message_data.size, true, agent_name)
        pad_path = options[:padpath] || pad_info[:pad_path]
        pad_num = options[:numpad] || pad_info[:pad_num]
        
        agent_info = agent_name ? " for agent '#{agent_name}'" : ""
        NumberStation.log.info "Using pad#{agent_info}: #{File.basename(pad_path)}, pad number: #{pad_num}"
      else
        pad_path = options[:padpath]
        pad_num = options[:numpad]
      end
      
      encrypted = NumberStation.encrypt_message(message_data, pad_path, pad_num, message_file_path)
      NumberStation.log.debug "encrypted_message: #{encrypted}"
      
      # Output encrypted message to stdout if encrypting from string without agent
      # (If agent is specified, we save to file instead)
      unless message_file_path
        puts encrypted
      end
    end


    desc "decrypt [MESSAGE --file FILE --numpad NUMPAD --padpath PADPATH]", "Decrypt a message using the key: NUMPAD in one time pad PADPATH"
    long_desc <<-DECRYPT_MESSAGE_LONG_DESC
    Decrypt a message using key NUMPAD in one-time-pad PADPATH
    
    Parameters:
      MESSAGE - Encrypted message string to decrypt (if --file is not provided)
      --file FILE - Path to encrypted message file (alternative to passing message as argument)
      --numpad NUMPAD (optional, will try to auto-detect if not provided)
      --padpath PADPATH (optional, will try to auto-detect if not provided)

    If --numpad or --padpath are not specified, the system will attempt to find a matching pad.
    Note: Auto-detection may be slower as it tries multiple pads.
    
    Examples:
      number_station decrypt "a1b2c3d4e5" --padpath ~/number_station/pads/Shadow/Shadow-2024-01-15.json --numpad 0
      number_station decrypt --file encrypted.txt --padpath ~/number_station/pads/Shadow/Shadow-2024-01-15.json --numpad 0
      number_station decrypt --file encrypted.txt
    DECRYPT_MESSAGE_LONG_DESC
    option :file, type: :string
    option :numpad, type: :string
    option :padpath, type: :string
    def decrypt(message = nil)
      # Handle help request
      if message == "help" || (message.nil? && options[:file].nil?)
        help("decrypt")
        return
      end
      
      ensure_config_loaded
      
      # Determine message content: from --file option or from argument
      if options[:file]
        unless File.exist?(options[:file])
          raise Thor::Error, "File not found: #{options[:file]}"
        end
        message_data = File.read(options[:file])
        message_file_path = options[:file]  # Store for filename generation
      elsif message && !message.empty?
        message_data = message
        message_file_path = nil
      else
        raise Thor::Error, "Either provide an encrypted message string as argument or use --file option"
      end
      
      # Auto-detect pad if not provided
      if options[:padpath].nil? || options[:numpad].nil?
        # For decryption, we don't require unconsumed pads (can decrypt with consumed pads)
        # Get cleaned message length for size check
        cleaned_message = message_data.gsub(/[\s\n\r]/, '')
        min_length = cleaned_message.length
        
        begin
          pad_info = NumberStation.find_next_available_pad(nil, min_length, false)
          pad_path = options[:padpath] || pad_info[:pad_path]
          pad_num = options[:numpad] || pad_info[:pad_num]
          
          NumberStation.log.info "Attempting decryption with pad: #{File.basename(pad_path)}, pad number: #{pad_num}"
        decrypted = NumberStation.decrypt_message(message_data, pad_path, pad_num, message_file_path)
        NumberStation.log.debug "decrypted_message: #{decrypted}"
        
        # Output decrypted message to stdout if decrypting from string
        unless message_file_path
          puts decrypted
        end
        rescue ArgumentError, StandardError => e
          NumberStation.log.error "Failed to decrypt with auto-detected pad: #{e.message}"
          NumberStation.log.error "Please specify --padpath and --numpad explicitly for accurate decryption"
          raise
        end
      else
        pad_path = options[:padpath]
        pad_num = options[:numpad]
        decrypted = NumberStation.decrypt_message(message_data, pad_path, pad_num, message_file_path)
        NumberStation.log.debug "decrypted_message: #{decrypted}"
        
        # Output decrypted message to stdout if decrypting from string
        unless message_file_path
          puts decrypted
        end
      end
    end


    desc "agents SUBCOMMAND", "Manage and view agent information"
    long_desc <<-AGENTS_LONG_DESC
    Manage agents in your number station configuration.
    
    Available subcommands:
      create NAME [--location LOCATION] [--handler HANDLER]
        Create a new agent
        
      activate NAME [--start-date DATE]
        Activate an agent
        
      deactivate NAME [--end-date DATE]
        Deactivate an agent
        
      update-handler NAME HANDLER
        Update handler codeword for an agent
        
      list
        Show condensed list of active agents
        
      list-all
        Show all active agents and inactive agents with end dates
        
      stats
        Show detailed statistics about active agents
    
    Examples:
      number_station agents create Shadow --location "Berlin" --handler "NIGHTFALL"
      number_station agents activate Shadow
      number_station agents list
      number_station agents stats
    
    For help on a specific subcommand:
      number_station agents help SUBCOMMAND
    AGENTS_LONG_DESC
    subcommand "agents", Agents

    desc "pad SUBCOMMAND", "Manage one-time pads"
    long_desc <<-PAD_LONG_DESC
    Manage one-time pads for encryption/decryption.
    
    Available subcommands:
      create [--name NAME --path PATH --numpads NUM --length LENGTH]
        Generate a new one-time pad file
        Use --name to create agent-specific pad directories
        
      stats [--path PATH]
        Show statistics about one-time pads in a directory
        
    Examples:
      number_station pad create --name Shadow --numpads 1000 --length 1000
      number_station pad create --name Shadow
      number_station pad create --path ~/number_station/pads --numpads 10 --length 500
      number_station pad create
      number_station pad stats
      number_station pad stats --path ~/custom/pads
    
    For help on a specific subcommand:
      number_station pad help SUBCOMMAND
    PAD_LONG_DESC
    subcommand "pad", Pad

    desc "version", "Print the version of the Number Stations gem."
    long_desc <<-VERSION_LONG_DESC
    Prints the version of the Number Stations gem.
    VERSION_LONG_DESC
    def version
      ensure_config_loaded
      puts NumberStation::VERSION
    end

    def self.exit_on_failure?
      false
    end

    # Remove the built-in 'tree' command
    def self.all_commands
      super.reject { |k, v| k == 'tree' }
    end

    private

    def ensure_config_loaded
      NumberStation::ConfigReader.read_config unless NumberStation.data
    end

    def load_message_component(type, override_path)
      resource_key = type.to_s
      config = NumberStation.data["resources"][resource_key]

      content = if override_path
        # For intro, outro, and repeat, read as-is (not converted to phonetic)
        File.read(override_path)
      elsif config && config["enabled"]
        # For intro, outro, and repeat, read as-is (not converted to phonetic)
        File.read(config["template"])
      else
        ""
      end
      
      # Strip trailing newlines to avoid extra blank lines when joining
      content.chomp
    end

    def find_config_template
      # Try multiple possible locations
      possible_paths = [
        File.expand_path(File.join(File.dirname(__FILE__), "../../resources/conf.yaml")),
        File.expand_path(File.join(File.dirname(__FILE__), "../../../resources/conf.yaml"))
      ]
      
      # Try gem datadir if available
      begin
        gem_path = File.join(Gem.datadir('number_station'), 'conf.yaml')
        possible_paths << gem_path if gem_path
      rescue
        # Gem.datadir not available, skip
      end
      
      possible_paths.find { |path| path && File.exist?(path) }
    end

    def find_resource_file(filename)
      # Try multiple possible locations for resource files
      possible_paths = [
        File.expand_path(File.join(File.dirname(__FILE__), "../../resources/#{filename}")),
        File.expand_path(File.join(File.dirname(__FILE__), "../../../resources/#{filename}"))
      ]
      
      # Try gem datadir if available
      begin
        gem_path = File.join(Gem.datadir('number_station'), filename)
        possible_paths << gem_path if gem_path
      rescue
        # Gem.datadir not available, skip
      end
      
      possible_paths.find { |path| path && File.exist?(path) }
    end

    def copy_message_template_files(target_path)
      # Copy intro_message.txt, outro_message.txt, and repeat_message.txt
      template_files = ['intro_message.txt', 'outro_message.txt', 'repeat_message.txt']
      
      template_files.each do |filename|
        source_file = find_resource_file(filename)
        target_file = File.join(target_path, filename)
        
        unless File.exist?(target_file)
          if source_file && File.exist?(source_file)
            FileUtils.cp(source_file, target_file)
            NumberStation.log.info "Created template file: #{target_file}"
          else
            NumberStation.log.warn "Template file not found: #{filename}"
          end
        else
          NumberStation.log.debug "Template file already exists: #{target_file}"
        end
      end
    end

    def create_default_config(target_file)
      default_config = <<~YAML
        logging:
          level: 0

        server:
          host: "0.0.0.0"
          port: 8080

        resources:
          intro:
            template: "intro_message.txt"
            enabled: true
          outro:
            template: "outro_message.txt"
            enabled: true
          repeat:
            template: "repeat_message.txt"
            enabled: false

        agent_list:
          - name: Abyss
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Ash
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Blade
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Blitz
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Cipher
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Cobra
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Dagger
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Drift
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Dusk
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Eclipse
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Enigma
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Fang
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Flux
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Frost
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Frostbite
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Ghost
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Grim
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Grimlock
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Havoc
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Helix
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Hunter
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Iron
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Ironclad
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Jinx
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Kraken
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Nexus
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Nightfall
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Nightshade
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Nova
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Nyx
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Obsidian
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Onyx
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Phantom
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Pulse
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Raptor
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Raven
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Razor
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Reaper
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Revenant
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Riven
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Rogue
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Saber
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Scorch
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Scorpion
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Shade
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Shadow
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Shard
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Slate
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Specter
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Storm
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Striker
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Surge
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Talon
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Tempest
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Thorn
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Titan
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Vantage
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Venom
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Vex
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Viper
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Void
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Voidwalker
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Vortex
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Wraith
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Zephyr
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
          - name: Zero
            location: null
            handler_codeword: null
            start_date: null
            end_date: null
            active: false
      YAML
      
      File.write(target_file, default_config)
    end
  end
end
