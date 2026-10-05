# A shared String handed to a parameter that only reads it, in a callee that
# hands control away before its last read (#7531). The callee took the
# String's live buffer; what ran while it was paused grew the String, the
# buffer moved, and the callee read the freed one. A callee that yields its
# Fiber keeps its own copy, as one that calls a method of the program does.
# Each String is made to read the same after the pause as before it, so the
# copy's answer is CRuby's.

# the last byte, through the length: grown by a megabyte ending in the same byte
def last_byte(s)
  Fiber.yield 1
  s.getbyte(s.bytesize - 1)
end

s = +"hello"
t = s
t << " world"
f = Fiber.new { last_byte(s) }
f.resume
s << ("x" * 1_000_000) << "d"
p f.resume

# the first byte and the length: grown, then set back to what it was
def head_and_size(s)
  Fiber.yield
  s.getbyte(0) + s.bytesize
end

u = +"hello"
v = u
v << " world"
g = Fiber.new { head_and_size(u) }
g.resume
u << ("y" * 1_000_000)
u.replace("hello world")
p g.resume
p u

# the handle is an instance variable; the method is reached through another
class Buf
  def initialize
    @buf = +"abc"
    @buf << "d"
  end

  def alias_it
    b = @buf
    b << "e"
  end

  def peek(s)
    Fiber.yield 1
    s.getbyte(0) + s.getbyte(s.bytesize - 1)
  end

  def step = peek(@buf)

  def grow
    @buf << ("z" * 1_000_000) << "e"
  end
end

b = Buf.new
b.alias_it
h = Fiber.new { b.step }
h.resume
b.grow
p h.resume
