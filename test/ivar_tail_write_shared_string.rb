# A method whose last statement stores a String in an instance variable
# answers that String (test/ivar_tail_write_return.rb). When the String is
# appended to in place under a second name the variable's slot is the shared
# handle, which a String return cannot take as it stands, and the method
# answered nil: the memo below printed nil the first time it was asked.
class Page
  def text
    return @text if @text
    b = +""
    b << "x" << "y"
    @text = b
  end
end
c = Page.new
p c.text, c.text

# the value is a parameter another method appends to, a local changed by
# `concat` or by a bang method, a second name of the local
class Sink
  attr_reader :t
  def set(s)
    @t = s
  end
  def add(x)
    @t << x
    self
  end
  def build(n)
    x = +"a"
    x.concat(n)
    @u = x
  end
  def up(n)
    x = n.dup
    x.upcase!
    @w = x
  end
  def twin(n)
    x = +"k"
    x << n
    y = x
    y << "."
    @y = y
  end
end
k = Sink.new
p k.set(+"q")
k.add("!")
p k.t
r = k.build("b")
p r, r.to_s.size
puts "got #{k.build("c")}"
p k.up("ab")
p k.twin("z")
puts "none" unless k.build("d")

# at the top level, in a class method, in a module's method
def top(n)
  x = +"t"
  x << n
  @top = x
end
p top("1")

class Reg
  def self.put(n)
    x = +"r"
    x << n
    @last = x
  end
  def self.last = @last
end
p Reg.put("2"), Reg.last

module Named
  def name_it(n)
    x = +"m"
    x << n
    @name = x
  end
end
class Thing
  include Named
end
p Thing.new.name_it("3")

# under a rescue, as an arm of an `if`, behind an `ensure`
class Safe
  def make(n)
    x = +"s"
    x << n
    @v = x
  rescue ArgumentError
    "e"
  end
  def pick(n)
    if n.size < 3
      x = +"i"
      x << n
      @v = x
    else
      "long"
    end
  end
  def done(n)
    x = +"d"
    x << n
    @v = x
  ensure
    @n = 1
  end
end
s = Safe.new
p s.make("4"), s.pick("5"), s.pick("long"), s.done("6")

# a method nobody asks keeps storing
class Quiet
  attr_reader :v
  def put(n)
    x = +"q"
    x << n
    @v = x
  end
end
q = Quiet.new
q.put("7")
p q.v
