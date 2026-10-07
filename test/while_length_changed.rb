# A loop whose test reads a String's length reads it again at each test when
# something in the loop can change a String. It was read once ahead of the
# loop unless the loop named the String under one of a list of mutators, so
# the loop ran to the old length for every change the list did not spell.
def grow(x)
  x << "!"
end

def grow_twice(x)
  grow(x)
  grow(x)
end

class Holder
  def initialize(v)
    @v = v
  end

  def add
    @v << "!"
  end
end

# a method appends to its parameter
s = +"ab"
i = 0
while i < s.length
  grow(s) if i < 3
  i += 1
end
p [i, s]

# two calls deep, and `until`
s = +"ab"
i = 0
until i >= s.size
  grow_twice(s) if i < 2
  i += 1
end
p [i, s]

# a second name for the String
s = +"ab"
t = s
i = 0
while i < s.length
  t << "!" if i < 3
  i += 1
end
p [i, s]

# a lambda that holds it
s = +"ab"
add = -> { s << "!" }
i = 0
while i < s.length
  add.call if i < 3
  i += 1
end
p [i, s]

# a block that appends (right before and after: the walk saw it by name)
s = +"ab"
i = 0
while i < s.length
  2.times { s << "!" } if i < 2
  i += 1
end
p [i, s]

# an Array and a Hash that hold it
s = +"ab"
a = [s]
h = { k: s }
i = 0
while i < s.length
  a[0] << "!" if i < 2
  h[:k] << "?" if i == 2
  i += 1
end
p [i, s]

# an object that holds it
s = +"ab"
b = Holder.new(s)
i = 0
while i < s.length
  b.add if i < 3
  i += 1
end
p [i, s]

# mutators the list did not name
s = +"abcdef"
i = 0
while i < s.length
  s.chop! if i == 0
  i += 1
end
p [i, s]
s = +"zz"
i = 0
while i < s.length
  s.succ! if i == 0
  i += 1
end
p [i, s]
s = +"abc   "
i = 0
while i < s.length
  s.rstrip! if i == 0
  i += 1
end
p [i, s]

# a receiver that is not the bare local (right before and after)
s = +"ab"
i = 0
while i < s.length
  (s) << "!" if i < 3
  i += 1
end
p [i, s]
s = +"ab"
i = 0
while i < s.length
  s.itself << "!" if i < 3
  i += 1
end
p [i, s]

# its encoding changed through a second name
s = +"\u00e9\u00e9"
t = s
i = 0
while i < s.length
  t.force_encoding("BINARY") if i == 0
  i += 1
end
p [i, s.length]

# a write through a target
s = +"ab"
i = 0
while i < s.length
  s, j = "abcdef", 0 if i == 0
  i += 1
end
p [i, s]

# a loop in the loop, on the same String
s = +"ab"
i = 0
n = 0
while i < s.length
  j = 0
  while j < s.length
    grow(s) if i == 0 && j < 2
    j += 1
    n += 1
  end
  i += 1
end
p [i, n, s]

# loops nothing can change a String in keep the one read: right before and after
def scan(s, c)
  i = 0
  while i < s.length
    return i if s[i] == c
    i += 1
  end
  -1
end
p [scan("hello", "l"), scan("hello", "z")]
names = { "a" => "one", "b" => "two" }
s = "abca"
out = ""
i = 0
while i < s.length
  out = out + names[s[i]] if names.key?(s[i])
  i += 1
end
p [i, out]
s = "hello world"
i = 0
n = 0
while i < s.length
  j = i
  while j < s.length && s.getbyte(j) != 32
    j += 1
  end
  n += j - i
  i = j + 1
end
p [i, n]
