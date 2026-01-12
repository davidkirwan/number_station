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

module NumberStation
  def self.generate_glados_espeak(input_file_path)
    # Read message from file
    message = File.read(input_file_path)
    
    # Generate output filename: remove .txt extension and append .xml
    input_basename = File.basename(input_file_path, File.extname(input_file_path))
    output_filename = "#{input_basename}.xml"
    output_path = File.join(File.dirname(input_file_path), output_filename)
    
    # Process message into GLaDOS-style XML
    # Split by whitespace but preserve the structure - handle spaces and newlines
    # Split on whitespace boundaries but keep track of what was between words
    sentence = "<speak version=\"1.0\" xmlns=\"\" xmlns:xsi=\"\" xsi:schemaLocation=\"\" xml:lang=\"\"><voice gender=\"female\">"
    sentenceend = "</voice></speak>"

    # Split message into words, preserving spacing structure
    # Use a regex that captures words and the whitespace after them
    parts = message.split(/(\s+)/)
    
    parts.each do |part|
      if part.match?(/^\s+$/)
        # This is whitespace - preserve it (spaces or newlines)
        sentence += part
      elsif !part.empty?
        # This is a word - wrap it in prosody tags
        sentence += template(part)
      end
    end

    final = sentence + sentenceend

    # Write XML file
    File.write(output_path, final)
    if NumberStation.respond_to?(:log) && NumberStation.log
      NumberStation.log.info "Generated GLaDOS espeak XML: #{output_path}"
    end
    
    output_path
  end

  private

  def self.template(word)
    sign = randomsign() || ""
    "<prosody pitch=\"#{sign + rand(0..80).to_s}\">#{word}</prosody>"
  end

  def self.randomsign()
    rnum = rand(0..1)

    if rnum == 0
      return "-"
    else
      return "+"
    end
  end
end
