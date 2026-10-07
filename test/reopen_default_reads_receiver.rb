# A default a call leaves out runs on the receiver, in a method the program
# adds to String, Symbol, Float, Range or Time: `"abc".note` against
# `def note(k = self + "!")` reads "abc", whoever calls it.
#
# The site that takes such a receiver without a block wrote the default where
# the call stands, on the caller's self. From another object that was the
# caller's answer (`n x!`); from the top level there is no self, and the C did
# not build. The receiver is held where the call stands, so what the statement
# runs before the call still runs before it; a call that gives every such
# default holds nothing. The same site takes self in a method added to Integer.

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
  def kind(k = self.class) = "k #{k}"
  def me = note
  def me2 = kind
  def ask(i) = i.note
end

class Time
  def stamp(k = self.to_i) = "t #{k}"
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

# Integer, from one of its own methods; Time
puts 4.me
puts 1.ask(z + 4)
puts 4.me2
puts Time.at(z + 5).stamp

# the statement's order: what stands before the call runs before its receiver
$log = []
def side = ($log << "side"; "s")
def fresh = ($log << "fresh"; "ab" + ARGV.size.to_s)
def two(a, b) = "#{a}/#{b}"

class String
  def m(k = self + "!") = "m #{k}"
  def q(a = "d", k: self) = "q #{a} #{k}"
  def lg = ($log << "lg"; self)
  def join2(o) = self + "+" + o
  def shapes
    r = []
    r << "#{side}#{lg.m}"
    r << side + lg.m
    r << [side, lg.m].join("-")
    h = {}
    h[side] = lg.m
    r << h["s"]
    a = []
    a << side << lg.m
    r << a.join("-")
    r << two(side, lg.m)
    r << (side == lg.m).to_s
    r << { side => lg.m }.size.to_s
    r << side.join2(lg.m)
    r << (side.size > 0 ? lg.m : "no")
    r << (side && lg.m)
    r << (side.empty? || lg.m).to_s
    r << "#{side}" + lg.q
    r << two(lg.q("x"), side)
    r << [side, lg.q(k: "g"), side].join("-")
    r << lg.m + side
    r << lg.m(lg.m)
    r
  end
end

s = "ab" + ARGV.size.to_s
puts s.shapes
puts $log.join(",")

# at the top level, and a keyword the call gives or leaves out
$log = []
puts "#{side}#{fresh.m}"
puts "#{side}#{fresh.q(k: "g")}"
puts two(side, fresh.q("x"))
kw = { k: "h" }
puts s.q(**kw)
puts $log.join(",")
