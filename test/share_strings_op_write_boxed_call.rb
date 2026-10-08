# `y[0] += "b"` on a receiver that a call hands back. With a Struct in the
# program the write is `y[0]` and `y[0] = ...`, and --share-strings asks
# whether that `[]=` could be changing a String another name holds. A
# receiver from a call to the program's one top-level method of that name
# is no String when none of the method's values is: its last statement and
# each `return`.
Pair = Struct.new(:a)

def by_index(i) = [["a"], { 0 => "a" }][i]
def by_cond(i) = i > 0 ? { 0 => "a" } : ["a"]

def by_return(i)
  return { 0 => "a" } if i > 0
  ["a"]
end

def by_block_return(i)
  [1, 2].each { |x| return { 0 => "a" } if i >= x }
  ["a"]
end

def by_call(i) = by_cond(i)

def by_local(i)
  r = i > 0 ? { 0 => "a" } : ["a"]
  r
end

def by_if(i)
  if i > 0
    { 0 => "a" }
  else
    ["a"]
  end
end

def or_number(i) = i > 0 ? 7 : ["a"]

def in_method(i)
  y = by_cond(i)
  z = y
  y[0] += "b"
  "#{y.class} #{y[0]} #{z[0]} #{y.equal?(z)}"
end

n = ARGV.size
y = by_index(n)
z = y
y[0] += "b"
puts "#{y.class} #{y[0]} #{z[0]} #{y.equal?(z)}"
y = by_index(n + 1)
z = y
y[0] += "b"
puts "#{y.class} #{y[0]} #{z[0]} #{y.equal?(z)}"
y = by_cond(n)
y[0] += "b"
puts "#{y.class} #{y[0]}"
y = by_cond(n + 1)
y[1] ||= "c"
puts "#{y.class} #{y[0]} #{y[1]}"
y = by_return(n)
y[0] = y[0] + "b"
puts "#{y.class} #{y[0]}"
y = by_return(n + 1)
y[0] += "b"
puts "#{y.class} #{y[0]}"
y = by_block_return(n)
y[0] += "b"
puts "#{y.class} #{y[0]}"
y = by_block_return(n + 2)
y[0] += "b"
puts "#{y.class} #{y[0]}"
y = by_call(n)
x = y[0]
y[0] += "b"
puts "#{y.class} #{y[0]} #{x}"
y = by_local(n + 1)
y[0] += "b"
puts "#{y.class} #{y[0]}"
y = by_if(n)
y[1] ||= "c"
puts "#{y.class} #{y[0]} #{y[1]}"
y = or_number(n)
y[0] += "b"
puts "#{y.class} #{y[0]}"
puts in_method(n)
puts in_method(n + 1)
# the Struct's own element write is as it was
s = Pair.new("a".dup)
t = s
s[0] += "b"
puts "#{s.a} #{t.a}"
