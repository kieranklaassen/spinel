# A replace source that no call makes is kept alive while replace copies it.
# The statement form of replace copies its source into a new String. A
# String two names hold is read as a copy, and where that read is one side
# of a choice (`t || "x"`, `c ? t : "x"`, a case) nothing held the copy
# while the new String was allocated; nor where the source is a write to
# such a String (`w ||= "x"`, `w = "abc"`), whose value is the String read
# back, a copy too. Nor did anything hold the String an object's to_str
# makes, where the source is the object itself: alone, in an instance
# variable, boxed beside a String, or as one side of a choice.
# Each line counts the Strings that came out wrong; the last one is for
# sources something else holds, which are read where they stand.
# spinel: gc-stress
class Named
  attr_accessor :s
  def initialize(s) = @s = s
  def to_str = @s + "!"
end

class Box
  def initialize
    @s = +"qrst"
    @t = +"sh"
    @o = Named.new("v")
  end

  def refill(n)
    @t = +"sh"
    u = @t
    u << n.to_s
    @s.replace(@t || "x")
    @s
  end

  def named(n)
    @o.s = "v" + n.to_s
    s = +"qrst"
    s.replace(@o)
    s
  end
end

N = 300
box = Box.new
by_or = by_choice = by_case = by_ivar = 0
by_object = by_member = by_boxed = by_either = 0
by_or_write = by_choice_write = by_write = 0
held = 0
N.times do |i|
  t = +"sh"
  u = t
  u << i.to_s
  c = i.odd?
  o = Named.new("v")
  o.s = "v" + i.to_s
  a = "pl" + i.to_s

  s = +"qrst"
  s.replace(t || "x")
  by_or += 1 unless s == "sh#{i}"

  s = +"qrst"
  s.replace(c ? t : "x")
  by_choice += 1 unless s == (c ? "sh#{i}" : "x")

  s = +"qrst"
  n = i % 3
  s.replace(case n when 0 then t when 1 then "one" else "two" end)
  by_case += 1 unless s == (n == 0 ? "sh#{i}" : n == 1 ? "one" : "two")

  by_ivar += 1 unless box.refill(i) == "sh#{i}"

  s = +"qrst"
  s.replace(o)
  by_object += 1 unless s == "v#{i}!"

  by_member += 1 unless box.named(i) == "v#{i}!"

  s = +"qrst"
  v = c ? "odd" + i.to_s : o
  s.replace(v)
  by_boxed += 1 unless s == (c ? "odd#{i}" : "v#{i}!")

  s = +"qrst"
  s.replace(c ? o : "x")
  by_either += 1 unless s == (c ? "v#{i}!" : "x")

  w = +"sh"
  x = w
  x << i.to_s
  s = +"qrst"
  s.replace(w ||= "x")
  by_or_write += 1 unless s == "sh#{i}"

  s = +"qrst"
  s.replace(c ? (w ||= "x") : "y")
  by_choice_write += 1 unless s == (c ? "sh#{i}" : "y")

  s = +"qrst"
  s.replace(w = "abc")
  by_write += 1 unless s == "abc"

  s = +"qrst"
  s.replace(a)
  held += 1 unless s == "pl#{i}"
  s.replace(c ? a : "x")
  held += 1 unless s == (c ? "pl#{i}" : "x")
  s.replace(a || "x")
  held += 1 unless s == "pl#{i}"
  s.replace(t)
  held += 1 unless s == "sh#{i}"
end
p by_or
p by_choice
p by_case
p by_ivar
p by_object
p by_member
p by_boxed
p by_either
p by_or_write
p by_choice_write
p by_write
p held
