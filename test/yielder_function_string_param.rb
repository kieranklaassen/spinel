# A yielding method that calls itself is compiled as a function. Its String
# parameter is a copy, which these calls cannot observe.
def countdown(out, n)
  out << n.to_s
  if n > 0
    countdown(out, n - 1) { |v| yield v }
  else
    yield out.size
  end
end
# a literal: nothing else can see its growth
p countdown(+"", 3) { |v| v * 2 }
# a local read nowhere else
buf = +"n"
p countdown(buf, 2) { |v| v + 1 }
# a parameter the method only reads
def depth(path, n)
  if n > 0
    depth(path, n - 1) { |v| yield v + 1 }
  else
    yield path.size
  end
end
name = +"abc"
p depth(name, 4) { |v| v * 10 }
p name
# an Array is shared
def collect(acc, n)
  acc << n
  if n > 0
    collect(acc, n - 1) { |v| yield v }
  else
    yield acc.size
  end
end
list = []
p collect(list, 3) { |v| v }
p list
# a yielding method that does not call itself is spliced into its call,
# where its parameter is the caller's String
def mark(out)
  out << "!"
  yield out.size
end
s = +"ab"
p mark(s) { |v| v + 1 }
p s
# a class method and an instance method, each handed a literal
class Walk
  def self.down(out, n)
    out << "c"
    return yield(out) if n == 0
    down(out, n - 1) { |v| yield v }
  end
  def up(out, n)
    out << "i"
    n > 0 ? up(out, n - 1) { |v| yield v } : yield(out)
  end
end
p Walk.down(+"", 2) { |v| v + "." }
p Walk.new.up(+"", 2) { |v| v.size }
