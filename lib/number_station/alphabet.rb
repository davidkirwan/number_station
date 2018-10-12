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

  def self.lookup(c)
    begin
      return NumberStation::ALPHABET[c] + ' ' || ' '
    rescue Exception => e
      return ' '
    end
  end

end