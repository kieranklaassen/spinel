# setbyte on a String held under two names, or reached through a reader,
# writes into the String's own buffer. An argument that appends to the same
# String moves that buffer, so the byte belongs in the new one.

# the value appends
s = +"abc"
t = s
p s.setbyte(0, (s << ("x" * 4000); 0x41))
p s[0, 4]
p t[0, 4]
p s.bytesize

# the index appends
s = +"abc"
t = s
p s.setbyte((s << ("x" * 4000); 1), 0x42)
p s[0, 4]
p t[0, 4]

# an index only the grown String has
s = +"abc"
t = s
p s.setbyte((s << ("x" * 4000); 4002), 0x5a)
p s[-3, 3]
p t.bytesize

# through a reader
class Box
  attr_reader :b
  def initialize(b)
    @b = b
  end
end
u = +"abc"
o = Box.new(u)
p o.b.setbyte(0, (o.b << ("x" * 4000); 0x43))
p o.b[0, 4]
p u[0, 4]
p u.bytesize

# out of range of the grown String still raises
s = +"abc"
t = s
begin
  s.setbyte((s << ("x" * 40); 43), 0x41)
rescue IndexError => e
  puts e.message
end
p t.bytesize

# a small append, a negative index
s = +"abc"
t = s
p s.setbyte(-1, (s << ("x" * 40); 0x5a))
p s
p t.getbyte(-1)

# plain arguments write where they did
s = +"abc"
t = s
p s.setbyte(1, 0x51)
p t

# the index runs before the value
log = []
s = +"abc"
t = s
p s.setbyte((log << "index"; 0), (log << "value"; 0x41))
p log, t

# an argument that freezes the String: the write raises
s = +"abc"
t = s
begin
  s.setbyte(0, (s.freeze; 0x41))
rescue FrozenError => e
  puts e.class
end
p t
s = +"abc"
t = s
begin
  s.setbyte((s.freeze; 1), 0x41)
rescue FrozenError => e
  puts e.class
end
p t

# the index is tested first: one outside the String raises IndexError,
# whether an argument froze the String or it was frozen before
s = +"abc"
t = s
begin
  s.setbyte((s.freeze; 50), (s.freeze; 0x41))
rescue => e
  puts e.class
end
begin
  s.setbyte((s.frozen?; -4), 0x41)
rescue => e
  puts e.class
end
begin
  s.setbyte((s.frozen?; -3), 0x41)
rescue => e
  puts e.class
end
p t

# a reader's String that nothing else holds stays held while an argument
# allocates
def churn
  a = []
  40.times { |i| a << ("s" + i.to_s) * 3 }
  a
end
def fresh = Box.new(+"abcdef")
keep = []
p fresh.b.setbyte(0, (keep << churn.last; 0x41))
p fresh.b.setbyte((keep << churn.last; 1), 0x42)
p keep.size
