# An error's class held in a variable while Strings are made. `e.class` named
# the class with a fresh copy on the string heap, and a Class value is a plain
# struct no root knows: the copy was collected under the variable, and the
# class then answered with whichever String took its place.
def fail_with(i)
  raise ArgumentError, "bad #{i}" if i % 2 == 0
  raise KeyError, "missing #{i}"
end

def churn(n)
  keep = []
  j = 0
  while j < n
    keep << "junk-" + (j % 10).to_s + "-junk-"
    j += 1
  end
  keep.size
end

def shown(k, n)
  churn(n)
  k.to_s
end

class Holder
  def initialize(k) = @k = k
  def shown(n)
    churn(n)
    @k.to_s
  end
end

to_s = name = inspect = interp = same = param = ivar = 0
1000.times do |i|
  want = i % 2 == 0 ? "ArgumentError" : "KeyError"
  begin
    fail_with(i)
  rescue => e
    k = e.class
    churn(400)
    to_s += 1 unless k.to_s == want
    k = e.class
    churn(400)
    name += 1 unless k.name == want
    k = e.class
    churn(400)
    inspect += 1 unless k.inspect == want
    k = e.class
    churn(400)
    interp += 1 unless "#{k}!" == want + "!"
    k = e.class
    churn(400)
    same += 1 unless (k == ArgumentError) == (i % 2 == 0) && (k == KeyError) == (i % 2 == 1)
    param += 1 unless shown(e.class, 400) == want
    ivar += 1 unless Holder.new(e.class).shown(400) == want
  end
end
p to_s, name, inspect, interp, same, param, ivar

# the name is the class's own, and a String made from it is the caller's
begin
  fail_with(0)
rescue => e
  s = e.class.to_s
  s << "!"
  t = e.class.to_s
  t.upcase!
  p s, t, e.class.to_s, e.class.name, e.class
  p e.class.to_s.frozen?, e.class.name.frozen?, e.class.name.equal?(ArgumentError.name)
end
