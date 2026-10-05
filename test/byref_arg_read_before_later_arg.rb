# A String variable handed to a method that appends to it, beside a later
# argument that is a call, is read ahead of that argument, so the callee
# binds the String the variable held even when the argument assigns the
# variable. What was lent then was a temp, and the appends stayed in it
# although nothing in the program could assign the variable:
# `emit(@out, l.strip)` and `emit($out, i.to_s)` left the buffer as it was.
# An instance variable only `initialize` assigns, and a global or a class
# variable only the top level assigns, is lent its own slot.
def one = 1
def mk(n) = "m" * n
def app(buf, s) = buf << s

class W
  def initialize
    @out = +""
  end

  def emit(buf, s) = buf << s

  def pair(buf, a, b) = buf << a << b

  def run(lines)
    lines.each { |l| emit(@out, l.strip) }
    emit(@out, format("%03d", 7))
    pair(@out, lines[0] + "!", lines[1])
    @out
  end
end
puts W.new.run([" a ", " b "])

# a global, beside a builtin's call, a method's and a keyword's value
$out = +""
3.times { |i| app($out, i.to_s) }
app($out, mk(40))
puts $out

def kw(buf, s:) = buf << s
$k = +"k"
kw($k, s: "a".upcase * 40)
puts $k

# a class variable
class Log
  @@all = +"all:"
  def self.put(buf, s) = buf << s

  def self.run
    put(@@all, mk(40))
    @@all
  end
end
puts Log.run

# the same variable in two parameters
def both(a, b, n)
  a << "x" * n
  b << "y" * n
end
$two = +"two:"
both($two, $two, one * 40)
puts $two

# a later argument that appends to the variable itself, and a callee that
# prints and loops
class Page
  def initialize
    @body = +"page:"
  end

  def header
    @body << "h" * 40
    1
  end

  def fill(buf, n)
    puts "filling"
    n.times { buf << "f" * 40 }
    buf.size
  end

  def run
    fill(@body, header)
    @body
  end
end
puts Page.new.run

# an overriding method appends too
class Base
  def initialize
    @log = +"base:"
  end

  def note(buf, s) = buf << s

  def run
    note(@log, mk(40))
    @log
  end
end

class Twice < Base
  def note(buf, s)
    i = 0
    while i < 2
      buf << s
      i += 1
    end
    buf
  end
end
puts Base.new.run
puts Twice.new.run

# a later argument that assigns the variable: the callee appends to the
# String the variable held, and the variable holds the new one
$a = +"a"
app($a, ($a = +"n"; mk(40)))
puts $a

class R
  def initialize
    @buf = +"r"
  end

  def reset
    @buf = +"new"
    mk(40)
  end

  # a callee that assigns the variable it was handed appends to the old one
  def swap(buf, s)
    @buf = +"swapped"
    buf << s
  end

  def add(buf, s) = buf << s

  def run
    add(@buf, reset)
    first = @buf.size
    swap(@buf, mk(40))
    [first, @buf]
  end
end
puts R.new.run

# a long buffer under the collector
class Big
  def initialize
    @big = +""
  end

  def push(buf, s) = buf << s

  def run
    2000.times { |i| push(@big, "line #{i} " * 5) }
    @big
  end
end
o = Big.new.run
puts o.size
puts o[-12, 12]
