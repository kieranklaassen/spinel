# An object of the program's own class is splatted as itself in a program
# that also requires classes Spinel ships (a StringIO, a Tempfile): only
# those keep the form they had, since CRuby asks them for #to_a. A class of
# the program that includes Comparable, or sits beneath a builtin exception,
# is the program's own.
require "stringio"
require "tempfile"

class Foo; end
class Bar < Foo; end
class Cmp
  include Comparable
  def <=>(o) = 0
end
class Err < StandardError; end

def n(a) = a.class
def k(a, b = :none) = [a.class, b]
def m(*a) = a.size

sio = StringIO.new("")
tf = Tempfile.new
x = Foo.new
p n(*x)
p k(*x)
p m(*x)
y = Bar.new
p n(*y)
p k(*y)
c = Cmp.new
p n(*c)
e = Err.new
p n(*e)
p sio.string.size
p tf.class
