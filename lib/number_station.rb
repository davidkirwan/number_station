####################################################
# Ruby Number Station
# Author: David Kirwan https://gitub.com/davidkirwan
####################################################
require 'pastel'
require 'number_station/alphabet'
require 'number_station/cli'
require 'number_station/config_reader'
require 'number_station/version'


module NumberStation


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


  def self.call_espeak(filename)
    cmd = "espeak -ven+f3 -m -p 60 -s 180 -f #{filename} --stdout | ffmpeg -i - -ar 44100 -ac 2 -ab 192k -f mp3 output.mp3"
    `#{cmd}`
  end


  def self.run(message)
    filename = "/tmp/GLaDOS_tmp.xml"
    sentence = generate_sentence(message)
    write_template_file(filename, sentence)
    call_espeak(filename)
  end


  def self.read_message(file_name)
    message = ''

    f = File.open(file_name)
    raw_message = f.readlines()
    f.close()

    # puts raw_message.inspect

    raw_message.each do |i|
      # puts i
      i.gsub!(/\n/, "").strip.each_char do |c|
	# puts c.inspect
        message += NumberStation::lookup(c)
	# puts message
      end
    end

    return message + "\n"
  end

end
