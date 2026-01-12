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

  ALPHABET = {
    '0' => "zero",
    '1' => "one",
    '2' => "two",
    '3' => "three",
    '4' => "four",
    '5' => "five",
    '6' => "six",
    '7' => "seven",
    '8' => "eight",
    '9' => "nine",
    'a' => "alpha",
    'b' => "bravo",
    'c' => "charlie",
    'd' => "delta",
    'e' => "echo",
    'f' => "foxtrot",
    'g' => "gamma",
    'h' => "hotel",
    'i' => "india",
    'j' => "juliette",
    'k' => "kilo",
    'l' => "lima",
    'm' => "mike",
    'n' => "november",
    'o' => "oscar",
    'p' => "pappa",
    'q' => "quebec",
    'r' => "romeo",
    's' => "sierra",
    't' => "tango",
    'u' => "uniform",
    'v' => "victor",
    'w' => "whiskey",
    'x' => "xray",
    'y' => "yankee",
    'z' => "zulu"
  }.freeze

  def self.lookup_phonetic(char)
    phonetic = ALPHABET[char.downcase]
    phonetic ? phonetic : nil
  end


  def self.espeak_word_template(word)
    pitch = "#{random_sign}#{rand(0..200)}"
    "<prosody pitch=\"#{pitch}\">#{word}</prosody>"
  end

  def self.random_sign
    rand(0..1) == 0 ? "-" : "+"
  end

  def self.generate_sentence(message)
    words = message.split(" ")
    prosody_words = words.map { |word| espeak_word_template(word) }.join
    "<speak version=\"1.0\" xmlns=\"\" xmlns:xsi=\"\" xsi:schemaLocation=\"\" xml:lang=\"\"><voice gender=\"female\">#{prosody_words}</voice></speak>"
  end

  def self.write_espeak_template_file(filename, sentence)
    File.write(filename, sentence)
  end


  def self.call_espeak(input_file_path, output_file_path)
    unless NumberStation.command?('espeak') && NumberStation.command?('ffmpeg')
      NumberStation.log.error "number_station requires the espeak and ffmpeg utilities are installed in order to output an mp3 file."
      return
    end

    # Use GLaDOS voice settings by default
    voice_flag = "-ven+f3"
    cmd = "espeak #{voice_flag} -m -p 60 -s 180 -f #{input_file_path} --stdout | ffmpeg -i - -ar 44100 -ac 2 -ab 192k -f mp3 #{output_file_path}"
    `#{cmd}`
  end

  def self.write_mp3(message, output_file_path)
    # Use temporary file for espeak template
    template_file = "/tmp/espeak_tmp.xml"
    # Generate GLaDOS-style sentence
    sentence = generate_sentence(message)
    
    write_espeak_template_file(template_file, sentence)
    call_espeak(template_file, output_file_path)
  end

  def self.to_phonetic(file_name)
    raw_message = File.read(file_name)
    # Remove all whitespace from input
    cleaned_message = raw_message.gsub(/[\s\n\r]/, '')
    
    # Process in groups of 5 characters
    groups = cleaned_message.chars.each_slice(5).map do |group|
      # Convert each character in the group to phonetic
      group.map { |char| lookup_phonetic(char) }.compact.join(' ')
    end
    
    # Join groups with double space for readability
    groups.join('  ')
  end


end
