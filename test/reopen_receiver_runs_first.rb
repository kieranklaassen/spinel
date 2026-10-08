# The receiver of a call into a method the program adds to a builtin runs
# before the call's arguments, as it does for a class's own method, and is
# held while a rest or a default is made beside it.

$log = []

class Object
  def pair(a, *r) = "#{a.size} #{r.size}"
  def rest(*r) = "#{r.size} #{label}"
  def dflt(o = [1, "d", nil]) = "#{o.size} #{label}"
end

class String
  def pair(a) = "#{size} #{a.size}"
end

class Array
  def pair(a, b = 1) = "#{size} #{a.size} #{b}"
end

class Hash
  def pair(a) = "#{size} #{a.size}"
end

class Integer
  def pair(a, *r) = "#{self} #{a.size} #{r.size}"
end

class Numeric
  def pair2(a) = "#{self} #{a.size}"
end

class Symbol
  def pair(a) = "#{self} #{a.size}"
end

class Door
  def initialize
    @name = "door" + ARGV.size.to_s
    @parts = []
    2000.times { |i| @parts << [i, "p", nil] }
  end
  def label = @name
end

def door
  $log << "door"
  Door.new
end

def str
  $log << "str"
  "s" + ARGV.size.to_s
end

def ary
  $log << "ary"
  [1, "a", nil]
end

def hsh
  $log << "hsh"
  { "k" => ARGV.size }
end

def int
  $log << "int"
  ARGV.size + 4
end

def flt
  $log << "flt"
  ARGV.size + 4.5
end

def sym
  $log << "sym"
  ARGV.size > 0 ? :b : :a
end

def arg
  $log << "arg"
  [1, "a"]
end

puts door.pair(arg)
puts str.pair(arg)
puts ary.pair(arg)
puts hsh.pair(arg)
puts int.pair(arg)
puts flt.pair2(arg)
puts sym.pair(arg)
puts $log.join(" ")

# a rest, a splat and a default made in place beside a receiver built there
xs = [1, 2, ARGV.size]
puts Door.new.rest
puts Door.new.rest
puts door.rest(*xs)
puts Door.new.dflt
puts door.dflt

# an argument that only reads reads what the receiver left
$g = "g"
def setg
  $g = "set"
  "s" + ARGV.size.to_s
end
puts setg.pair($g)
$g = "g"
puts setg.pair("#{$g}!")
puts((x = "x" + ARGV.size.to_s).pair("#{x}!"))
