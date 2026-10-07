# An append chain on a reader's String: every link is appended to the
# reader's String, wherever the chain stands, and where its value is read
# the value is that String's text.

class Page
  attr_reader :text
  attr_accessor :note

  def initialize(t)
    @text = +t
    @note = +"n"
  end

  # the chain as a method's last expression: bare reader, and self.reader
  def grow
    text << "x" << "y"
  end

  def more
    self.text << "p" << "q" << "r"
  end

  def back
    return text << "<" << ">"
  end

  # an argument gives the reader another String: the chain stays on the
  # String it started on
  def swap!
    @text = +"new"
    "s"
  end

  def swapped
    text << "a" << swap!
  end

  def marks(n)
    note << "(" << n.to_s << ")"
  end
end

class Book
  attr_reader :n

  def initialize
    @pages = [Page.new("p"), Page.new("q")]
    @n = 0
  end

  # a base that runs code runs once
  def nxt
    @n += 1
    @pages[@n - 1]
  end

  def take
    nxt.text << "a" << "b"
  end

  def all = @pages.map { |x| x.text }
end

def add(pg)
  pg.text << "a" << "b"
end

# under a condition, one branch a single link
def cond(pg, c)
  if c
    pg.text << "m" << "n"
  else
    pg.text << "o"
  end
end

def eight(pg)
  pg.text << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8"
end

# the chain as the value of a begin block
def guarded(pg)
  v = begin
    pg.text << "g" << "h"
  rescue
    "none"
  end
  v.size
end

def width(s) = s.size

pg = Page.new("t")
add(pg)
p pg.text
p add(pg)
p add(pg).size
p pg.text

pg.grow
p pg.more
p pg.back
p pg.text

p cond(pg, true)
p cond(pg, false).size
p pg.text

q = Page.new("")
p eight(q)
p eight(q).size
p q.text
p guarded(q)
p q.text

# the chain as an argument, a receiver, an operand, in an interpolation
w = Page.new("w")
p(w.text << "1" << "2")
p w.text
puts(w.text << "3" << "4" << "5")
p w.text
p((w.text << "6" << "7").size)
p w.text

u = Page.new("u")
p width(u.text << "8" << "9")
p u.text
p (u.text << "a" << "b") + "!"
p u.text
p "<#{u.text << "c" << "d"}>"
p u.text

v = Page.new("v")
p v.text.concat("e").concat("f")
p v.text
p((v.text << "g" << 104) == "vefgh")
p v.text
p v.marks(3)
p v.marks(40)
p v.note

b = Book.new
p b.take
p b.n
p b.all

r = Page.new("old")
p r.swapped
p r.text

# 65 links as a statement: past the 64 the statement form takes in one go
l = Page.new("")
l.text << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" << "1" << "2" << "3" << "4" << "5"
p l.text.size
p l.text[-5, 5]

# 17 links under a local write: the local is the reader's String
k = Page.new("")
s = k.text << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" << "1" << "2" << "3" << "4" << "5" << "6" << "7"
s << "!"
p k.text
p s.equal?(k.text)
