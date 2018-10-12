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
require 'pastel'
require 'json'
require 'logger'
require 'number_station/alphabet'
require 'number_station/cli'
require 'number_station/config_reader'
require 'number_station/make_pad'
require 'number_station/version'


module NumberStation

  def self.hexlify(s)
    a = []
    s.each_byte do |b|
      a << sprintf('%02X', b)
    end
    a.join
  end
 
  def self.unhexlify(s)
    a = s.split
    return a.pack('H*')
  end

  def self.command?(name)
    `which #{name}`
    $?.success?
  end  

  def self.set_log(log)
    @log = log
  end

  def self.log()
    return @log
  end

  def self.set_data(data)
    @data = data
  end

  def self.data()
    return @data
  end

  def self.word_template(word)
    return "<prosody pitch=\"#{randomsign + rand(0..200).to_s}\">#{word}</prosody>"
  end


  def self.randomsign()
    rand(0..1) == 0 ? "-" : "+"
  end


  def self.generate_sentence(message)
    sentence = ""
    message.split(" ").each do |i|
      sentence += word_template(i)
    end

    sentence_template = "<speak version=\"1.0\" xmlns=\"\" xmlns:xsi=\"\" xsi:schemaLocation=\"\" xml:lang=\"\"><voice gender=\"female\">#{sentence}</voice></speak>"
    return sentence_template
  end


  def self.write_template_file(filename, sentence)
    f = File.open(filename, "w")
    f.write(sentence)
    f.close
  end


  def self.call_espeak(input_file_path, output_file_path)
    cmd = "espeak -ven+f3 -m -p 60 -s 180 -f #{input_file_path} --stdout | ffmpeg -i - -ar 44100 -ac 2 -ab 192k -f mp3 #{output_file_path}"

    unless NumberStation.command?('espeak') || NumberStation.command?('ffmpeg')
      NumberStation.log.error "number_station requires the espeak and ffmpeg utilities are installed in order to output an mp3 file."
    else
      `#{cmd}`
    end
  end


  def self.run(message, output_file_path)
    filename = "/tmp/GLaDOS_tmp.xml"
    sentence = NumberStation.generate_sentence(message)
    NumberStation.write_template_file(filename, sentence)
    NumberStation.call_espeak(filename, output_file_path)
  end


  def self.read_message(file_name)
    message = ''

    f = File.open(file_name)
    raw_message = f.readlines()
    f.close()

    raw_message.each do |i|
      # puts i
      i.gsub!(/\n/, "").strip.each_char do |c|
        message += NumberStation.lookup(c)
      end
    end
    return message + "\n"
  end

end
