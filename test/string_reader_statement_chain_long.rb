# A statement append chain of more than 64 links on a String that is not a
# variable: a reader's. The statement arm walked 64 links and left a longer
# chain to the arms that write each link back to a variable; here there is
# none, so the first link reached the reader's String and the rest a copy.
class Page
  attr_reader :text, :inner
  attr_accessor :note
  def initialize(deep = true)
    @text = +"t"
    @note = +"n"
    @inner = deep ? Page.new(false) : nil
  end
  def body = @text
  def grow
    self.text << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
    self
  end
end
Line = Struct.new(:s)

pg = Page.new
pg.text << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
p pg.text.size
pg.note.concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc").concat("bc")
p pg.note.size, pg.note[-4, 4]
pg.body << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}" << "x" << "#{pg.note.size}"
p pg.text.size, pg.text[-6, 6]
pg.inner.text << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
p pg.inner.text.size
p Page.new.grow.text.size
ln = Line.new(+"s")
ln.s << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
p ln.s.size
w = "w"
(pg.text) << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w << w
p pg.text.size

# right before: 64 links on a reader, and more than 64 on a local
q = Page.new
q.text << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
p q.text.size
s = +"s"
t = s
s << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
p s.size, t.size
