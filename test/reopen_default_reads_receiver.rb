# A default a call leaves out runs on the receiver, in a method the program
# adds to String, Symbol, Range or Float: `"abc".note` against
# `def note(k = self + "!")` reads "abc", whoever calls it.
#
# The arms for Random, Array, Hash and a call with a block hold the receiver
# and let the default read it. The site that takes a String, Symbol, Range or
# Float receiver without a block wrote the default where the call stands, on
# the caller's self. From another object that was the caller's answer
# (`n x!`); from the top level there is no self, and the C did not build.
# The same site takes self in a method added to Integer.

module Tagged
  def label(k = base) = "l #{k}"
end

class String
  include Tagged
  def base = 9
  def note(k = self + "!") = "n #{k}"
  def wrap(a = "<", k = self.size) = "#{a}#{k}"
  def sort(k = self.class) = "s #{k}"
  def tagged(k = base) = "t #{k}"
  def ask(s) = s.note
end

class Symbol
  def note(k = self.to_s) = "n #{k}"
  def two(k = self.to_s, j = k + "?") = "#{k} #{j}"
end

class Range
  def note(k = self.first) = "n #{k}"
end

class Float
  def note(k = self * 2) = "n #{k}"
  def ask(f) = f.note
end

class Integer
  def note(k = self + 1) = "n #{k}"
  def me = note
  def ask(i) = i.note
end

class Room
  def base = 3
  def size = 99
  def first = 77
  def to_s = "room"
  def ask_str(s) = s.note
  def ask_wrap(s) = s.wrap(">")
  def ask_sort(s) = s.sort
  def ask_tagged(s) = s.tagged
  def ask_label(s) = s.label
  def ask_sym(y) = y.note
  def ask_two(y) = y.two
  def ask_range(r) = r.note
  def ask_float(f) = f.note
end

z = ARGV.size
room = Room.new

# from another String, from another object, from the top level
puts "x".ask("abc")
puts room.ask_str("abc")
puts (z.to_s + "abc").note
puts "abc".note("given")
puts room.ask_wrap("abc")
puts room.ask_sort("abc")
puts "abc".sort

# a method of the class's own in the default, and of a module it includes
puts room.ask_tagged("abc")
puts "abc".tagged
puts room.ask_label("abc")

# Symbol, Range, Float
puts room.ask_sym(:abc)
puts :abc.note
puts room.ask_two(:abc)
puts room.ask_range(z + 1..3)
puts (1..3).note
puts 1.5.ask(z + 2.5)
puts room.ask_float(z + 2.5)
puts 2.5.note

# Integer, from one of its own methods
puts 4.me
puts 1.ask(z + 4)
