######################################################
# Ruby Number Station
# Author: David Kirwan https://gitub.com/davidkirwan
# Licence: GPL 3.0
######################################################

class Char_list
  class << self
    attr_accessor :chars, :lookup

    @c = nil
    
    def chars
      @c ={
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
    end

    
    def lookup(c)
      begin
	x
      rescue Exception => e
	x
      end
    end


  end
end

