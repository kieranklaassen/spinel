# A local that holds a Regexp is read as its literal only where it can hold
# nothing else. The literal behind a local was looked up by name, once for the
# whole program, so two methods that each had a local `re` matched with the
# first one's pattern; and a local written twice, written in two branches, or
# a parameter also written, matched with its first literal whatever it held.
def one(s)
  re = /a/
  s.sub(re, "X")
end
def two(s)
  re = /b/
  s.sub(re, "Y")
end
p one("ab"), two("ab")

class Word
  def tag(s)
    re = /[a-z]+/
    s[re]
  end
end
class Number
  def tag(s)
    re = /\d+/
    s[re]
  end
end
p Word.new.tag("ab12"), Number.new.tag("ab12")

# written twice: a read sees the write that ran last
def twice(s)
  re = /a/
  first = s =~ re
  re = /b/
  [first, s =~ re, s.gsub(re, "-"), s.split(re), s.scan(re), s.match?(re)]
end
p twice("xab")

# the same pattern with other flags is another pattern
def flags(s)
  re = /B/i
  first = s =~ re
  re = /B/
  [first, s =~ re]
end
p flags("xab")

# written in two branches
def pick(s, wide)
  if wide
    re = /\w+/
  else
    re = /\d/
  end
  [s[re], s.match(re)[0], s.start_with?(re), s.partition(re)]
end
p pick("ab12", true), pick("ab12", false)

# a parameter also written
def param(s, re)
  re = /b/ if s.size > 3
  s.sub(re, "_")
end
p param("xab", /a/), param("xaba", /a/)

# written in a block, and in a multiple assignment
def in_block(s)
  re = /a/
  [1].each { re = /b/ }
  s.index(re)
end
def multi(s)
  re = /a/
  n, re = 1, /b/
  s.index(re) + n
end
p in_block("xab"), multi("xab")

# written only on one path, and read where it was
def late(s)
  re = /b/ if s.size > 2
  s.size > 2 ? s =~ re : nil
end
p late("xab"), late("ab")

# in a `when`
def kind(s)
  re = /\A\d+\z/
  re = /\A[a-z]+\z/ if s.size > 3
  case s
  when re then :hit
  else :miss
  end
end
p kind("12"), kind("ab"), kind("abcd"), kind("1234")

# scan: the rows are asked of the pattern that ran
def rows(s)
  re = /(a)(b)?/
  re = /(x)(a)/ if s.start_with?("x")
  out = []
  s.scan(re) { |m| out << m }
  s.scan(re) { |a, b| out << [b, a] }
  out + s.scan(re)
end
p rows("xab"), rows("ab")

# one pattern written twice is still that literal
def same(s)
  re = /a/
  re = /a/ if s.empty?
  s.sub(re, "X")
end
p same("xab")

# written in a loop and read after it: the loop may not run, so the read is
# asked at run time, and what is chained on the scan is typed for that
def after_loop(s)
  i = 0
  while i < 1
    re = /b/
    i += 1
  end
  s.scan(re).each { |x| p x }
  p s.scan(re).first, s.scan(re).map { |x| x.inspect }
  re.match?(s, 5)
end
p after_loop("xaybzab")
def first_pass(s)
  i = 0
  while i < 2
    re = /(b)(z)?/ if i == 0
    p s.scan(re).first if i == 1
    i += 1
  end
end
first_pass("xaybzab")
