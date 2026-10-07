# A String Range read from a global or a class variable is kept while the
# argument of its call runs.
#
# Ruby reads a call's receiver before its arguments, so `$r == f(i)` where
# `f` gives `$r` another Range compares the Range `$r` held before. The
# compiler reads the slot into a C temp ahead of the argument for that.
# A String Range is two Strings by value, and the temp rooted neither: once
# the argument had rebound the slot nothing else held them, the argument's
# own allocation collected them, and the call read two freed Strings.
#
# Every case stores a Range of two built Strings in the slot, then calls
# `==`, `!=`, `eql?`, `include?` or `member?` on it with an argument that
# rebinds the slot and allocates. Each line is the number of calls, of
# 1,000, that answered something else than Ruby does.

$r = ("a".."c")

def junk(i)
  a = []
  k = 0
  while k < 170
    a << "j#{k}" + i.to_s
    k += 1
  end
  a.size
end

def span(i)
  x = "a#{i}"
  y = "c#{i}"
  (x..y)
end

def rebind(i)
  $r = span(i + 1)
  junk(i)
  span(i)
end

def rebind_s(i)
  $r = span(i + 1)
  junk(i)
  "b#{i}"
end

class Box
  @@r = ("a".."c")

  def self.move(i)
    @@r = span(i + 1)
    junk(i)
    span(i)
  end

  def self.move_s(i)
    @@r = span(i + 1)
    junk(i)
    "b#{i}"
  end

  def self.eq(i)
    @@r = span(i)
    @@r == move(i)
  end

  def self.ne(i)
    @@r = span(i)
    @@r != move(i)
  end

  def self.inc(i)
    @@r = span(i)
    @@r.include?(move_s(i))
  end
end

def wrong(which)
  bad = 0
  i = 0
  while i < 1000
    ok = case which
         when 0
           $r = span(i)
           $r == rebind(i)
         when 1
           $r = span(i)
           !($r != rebind(i))
         when 2
           $r = span(i)
           $r.eql?(rebind(i))
         when 3
           $r = span(i)
           $r.include?(rebind_s(i))
         when 4
           $r = span(i)
           $r.member?(rebind_s(i))
         when 5 then Box.eq(i)
         when 6 then !Box.ne(i)
         else Box.inc(i)
         end
    bad += 1 unless ok
    i += 1
  end
  bad
end

puts "a global, ==: #{wrong(0)}"
puts "a global, !=: #{wrong(1)}"
puts "a global, eql?: #{wrong(2)}"
puts "a global, include?: #{wrong(3)}"
puts "a global, member?: #{wrong(4)}"
puts "a class variable, ==: #{wrong(5)}"
puts "a class variable, !=: #{wrong(6)}"
puts "a class variable, include?: #{wrong(7)}"
