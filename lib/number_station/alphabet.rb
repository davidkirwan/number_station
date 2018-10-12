######################################################
# Ruby Number Station
# Author: David Kirwan https://gitub.com/davidkirwan
# Licence: GPL 3.0
######################################################

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

  def self.lookup(c)
    begin
      return NumberStation::ALPHABET[c] + ' ' || ' '
    rescue Exception => e
      return ' '
    end
  end

end

