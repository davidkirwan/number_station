####################################################
# Ruby Number Station
# Author: David Kirwan https://gitub.com/davidkirwan
####################################################
require File.join(File.dirname(__FILE__), 'utils/char_lookup')


def word_template(word)
  return "<prosody pitch=\"#{randomsign + rand(0..200).to_s}\">#{word}</prosody>"
end


def randomsign()
  rand(0..1) == 0 ? "-" : "+"
end


def generate_sentence(message)
  sentence = ""
  message.split(" ").each do |i|
    sentence += word_template(i)
  end

  sentence_template = "<speak version=\"1.0\" xmlns=\"\" xmlns:xsi=\"\" xsi:schemaLocation=\"\" xml:lang=\"\"><voice gender=\"female\">#{sentence}</voice></speak>"
  return sentence_template
end


def write_template_file(filename, sentence)
  f = File.open(filename, "w")
  f.write(sentence)
  f.close
end


def call_espeak(filename)
  cmd = "espeak -ven+f3 -m -p 60 -s 180 -f #{filename} --stdout | ffmpeg -i - -ar 44100 -ac 2 -ab 192k -f mp3 output.mp3"
  `#{cmd}`
end


def run(message)
  filename = "tmp/GLaDOS_tmp.xml"
  sentence = generate_sentence(message)
  write_template_file(filename, sentence)
  call_espeak(filename)
end


def read_message(file_name)
  f = File.open(file_name)
  message = f.readlines()
  f.close()
  return message
end


###################################################
message, intro, body, outro = "", "", "", ""

intro = read_message("resources/intro_message.txt")
body = read_message("resources/body_message.txt")
outro = read_message("resources/outro_message.txt")
message = intro + body + outro
puts message
#run(message)
