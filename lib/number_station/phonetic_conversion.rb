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

  ALPHABET ={
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
  }


  def self.lookup_phonetic(c)
    begin
      return NumberStation::ALPHABET[c] + ' ' || ' '
    rescue Exception => e
      return ' '
    end
  end


  def self.espeak_word_template(word)
    return "<prosody pitch=\"#{randomsign() + rand(0..200).to_s}\">#{word}</prosody>"
  end


  def self.randomsign()
    return rand(0..1) == 0 ? "-" : "+"
  end


  def self.generate_sentence(message)
    sentence = ""
    message.split(" ").each {|i| sentence += espeak_word_template(i)}
    return "<speak version=\"1.0\" xmlns=\"\" xmlns:xsi=\"\" xsi:schemaLocation=\"\" xml:lang=\"\"><voice gender=\"female\">#{sentence}</voice></speak>"
  end


  def self.write_espeak_template_file(filename, sentence)
    f = File.open(filename, "w")
    f.write(sentence)
    f.close
  end


  def self.call_espeak(input_file_path, output_file_path)
    if NumberStation.data["resources"]["espeak"]["glados"]
      cmd = "espeak -ven+f3 -m -p 60 -s 180 -f #{input_file_path} --stdout | ffmpeg -i - -ar 44100 -ac 2 -ab 192k -f mp3 #{output_file_path}"
    else
      cmd = "espeak -m -p 60 -s 180 -f #{input_file_path} --stdout | ffmpeg -i - -ar 44100 -ac 2 -ab 192k -f mp3 #{output_file_path}"
    end

    unless NumberStation.command?('espeak') || NumberStation.command?('ffmpeg')
      NumberStation.log.error "number_station requires the espeak and ffmpeg utilities are installed in order to output an mp3 file."
    else
      `#{cmd}`
    end
  end


  def self.write_mp3(message, output_file_path)
    filename = NumberStation.data["resources"]["espeak"]["sentence_template"]
    if NumberStation.data["resources"]["espeak"]["glados"]
      sentence = NumberStation.generate_sentence(message)
    else
      sentence = message
    end
    NumberStation.write_espeak_template_file(filename, sentence)
    NumberStation.call_espeak(filename, output_file_path)
  end


  def self.to_phonetic(file_name)
    message = ''
    puts file_name
    f = File.open(file_name)
    raw_message = f.read()
    f.close()

    raw_message.each_char do |c|
      message += NumberStation.lookup_phonetic(c)
    end
    return message
  end


end
