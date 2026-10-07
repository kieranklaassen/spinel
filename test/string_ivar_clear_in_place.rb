# clear on an instance variable's String that the caller also holds empties
# that String: the caller sees it, and what is appended next starts from
# nothing.
class Box
  def initialize(b)
    @b = b
  end

  def b
    @b
  end

  def refill(x)
    @b.clear
    @b << x
  end

  def wipe
    @b.clear
    nil
  end

  def wipe_if(f)
    @b.clear if f
    @b << "q"
  end

  def each_part(parts)
    parts.each do |x|
      @b.clear
      @b << x
    end
    nil
  end

  def count_up
    i = 0
    while i < 3
      @b.clear
      @b << i.to_s
      i += 1
    end
  end

  def guarded
    begin
      @b.clear
    rescue FrozenError => e
      puts e.class
    end
    @b.size
  end
end

s = +"abc"
o = Box.new(s)
o.refill("rr")
p o.b, s
o.wipe
p o.b, s, s.size, s.empty?
s << "new"
p o.b
o.wipe_if(false)
p s
o.wipe_if(true)
p s
o.each_part(["one", "two"])
p s
o.count_up
p s
s << ("y" * 5000)
o.refill("z")
p s.size, s

# a frozen String still raises, and keeps its bytes
f = +"keep"
g = Box.new(f)
f.freeze
p g.guarded, f

# a class method's variable, and a top-level one
class Reg
  def self.keep(x)
    @k = x
  end

  def self.wipe
    @k.clear
    @k << "c"
  end
end
t = +"abc"
Reg.keep(t)
Reg.wipe
p t
u = +"abc"
@v = u
@v.clear
@v << "t"
p u
