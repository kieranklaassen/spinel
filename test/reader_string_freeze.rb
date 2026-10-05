# freeze and frozen? through a reader reach the String the object holds. A
# slot whose String is changed in place hands out a copy when it is read,
# and the copy has its own frozen flag: the freeze froze a String nobody
# else could see, and frozen? asked a fresh one.

class Note
  attr_reader :text
  def initialize(text)
    @text = text
  end
  def add(x)
    @text << x
    nil
  end
  def seal
    @text.freeze
    nil
  end
  def sealed?
    @text.frozen?
  end
end

# freeze as a statement
a = Note.new(+"q")
a.text << "z"
p a.text.frozen?
a.text.freeze
p a.text.frozen?, a.sealed?
begin
  a.text << "w"
rescue FrozenError => e
  p e.class
end
begin
  a.add("w")
rescue FrozenError => e
  p e.class
end
p a.text

# freeze as a value
b = Note.new(+"q")
r = b.text.freeze
p r, r.frozen?, b.text.frozen?
p b.text.freeze.size

# frozen by the object itself, by its caller
c = Note.new(+"q")
c.seal
p c.text.frozen?
f = +"q"
f.freeze
g = Note.new(f)
p g.text.frozen?

# a copy taken from a frozen slot is not frozen
h = a.text.dup
h << "k"
p h, h.frozen?, a.text

# in a condition, in a block, in a method, through another reader
i = Note.new(+"q")
puts "open" unless i.text.frozen?
i.text.freeze if i.text.size == 1
puts "sealed" if i.text.frozen?
j = Note.new(+"q")
[1].each { |x| j.text.freeze }
p j.text.frozen?
def seal_it(n)
  n.text.freeze
  n.text.frozen?
end
k = Note.new(+"q")
p seal_it(k), k.text.frozen?
class Box
  attr_reader :note
  def initialize(note)
    @note = note
  end
end
l = Box.new(Note.new(+"q"))
l.note.text << "z"
l.note.text.freeze
p l.note.text.frozen?, l.note.text

# the receiver runs once
def pick(n)
  puts "pick"
  n
end
m = Note.new(+"q")
pick(m).text.freeze
p pick(m).text.frozen?

# an inherited reader, on an instance of the subclass
class Memo < Note
end
o = Memo.new(+"q")
o.text << "z"
o.text.freeze
p o.text.frozen?, o.sealed?

# a memoizing reader
class Lazy
  def text = (@text ||= +"m")
end
q = Lazy.new
q.text << "z"
p q.text.frozen?
q.text.freeze
p q.text.frozen?, q.text

# a slot that holds nil
n = Note.new(nil)
p n.text.frozen?, n.text.freeze
