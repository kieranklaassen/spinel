# String#insert with an index past either end raises IndexError, and the
# String is left as it was. As a statement the insert went in at the end,
# or from the front dropped a character; with its value taken, a negative
# index below the start came back around to a place inside the String.

# a statement on a local, at every index from below the start to past the end
[-9, -4, -3, -2, -1, 0, 1, 2, 3, 9].each do |i|
  s = +"ab"
  begin
    s.insert(i, "x")
  rescue IndexError => e
    puts "IndexError: #{e.message}"
  end
  p s
end

# the value taken
[-4, -3, 2, 3].each do |i|
  s = +"ab"
  begin
    r = s.insert(i, "x")
    p r.equal?(s)
  rescue IndexError => e
    puts "IndexError: #{e.message}"
  end
  p s
end

# literal indexes, on a local no block holds
a = +"ab"
begin
  a.insert(3, "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
begin
  a.insert(-4, "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
begin
  p a.insert(-4, "x").size
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
a.insert(2, "x")
a.insert(-4, "y")
p a

# characters, not bytes
m = +"héllo"
begin
  m.insert(-7, "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
begin
  m.insert(6, "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
m.insert(5, "!")
m.insert(-7, "¿")
p m.size, m.bytesize, m == "¿héllo!"

# an instance variable, and a String two names hold
class Line
  def initialize
    @text = +"ab"
  end

  def put(i)
    @text.insert(i, "x")
  rescue IndexError => e
    puts "IndexError: #{e.message}"
  end

  def text
    @text
  end
end
l = Line.new
l.put(5)
l.put(-5)
l.put(1)
p l.text

b = +"ab"
c = b
begin
  b.insert(4, "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
b.insert(-1, "z")
p c, c.equal?(b)

# a receiver whose kind is known at run time
box = [+"ab", 1][0]
begin
  box.insert(-4, "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
p box

# a text whose kind is known at run time, as a statement
text = ["q", 1][0]
d = +"ab"
d.insert(1, text)
p d

# a frozen receiver: the index is checked first
f = "ab"
begin
  f.insert(1, "x")
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end
begin
  f.insert(7, "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
begin
  f.insert(-7, "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
p f

# a text that changes the receiver is read before the receiver is
o = +"abcd"
o.insert(1, (o << "ef"; "x"))
p o
