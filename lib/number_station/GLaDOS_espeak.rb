def template(word)
  sign = randomsign() || ""
  return "<prosody pitch=\"#{sign + rand(0..80).to_s}\">#{word}</prosody>"
end

def randomsign()
  rnum = rand(0..1)

  if rnum == 0
    return "-"
  else
    return "+"
  end
end


message = "This was a triumph! I'm making a note here, huge success."

words = message.split(" ")
sentence = "<speak version=\"1.0\" xmlns=\"\" xmlns:xsi=\"\" xsi:schemaLocation=\"\" xml:lang=\"\"><voice gender=\"female\">"
sentenceend = "</voice></speak>"

words.each do |i|
  sentence += template(i)
end

final = sentence + sentenceend


filename = "GLaDOS_espeak_config.xml"
f = File.open(filename, "w")
f.write(final)
f.close

cmd = "espeak -ven+f3 -m -p 60 -s 180 -f #{filename}"
`#{cmd}`
