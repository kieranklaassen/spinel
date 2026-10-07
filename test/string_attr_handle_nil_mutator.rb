# A String attribute that a mutator is called on through its reader is held
# as a handle. Where initialize sets the attribute and the program later
# writes nil into it, the handle is NULL while it is nil, and a mutator
# called through the reader (on a local, on self, through another reader)
# raises NoMethodError, as on any nil. A String that is there is changed in
# place, as before.

class Note
  attr_accessor :text

  def initialize
    @text = +"ab"
  end

  def drop
    @text = nil
  end

  def stamp
    text << "!"
    text
  rescue NoMethodError => e
    e.message.end_with?("<<' for nil")
  end

  def swap
    @text = +"q"
    "z"
  end
end

class Folder
  attr_reader :note

  def initialize
    @note = Note.new
  end
end

def filed(f)
  f.note.text.upcase!
  f.note.text
rescue NoMethodError => e
  e.message.end_with?("upcase!' for nil")
end

def appended(n)
  n.text << "c"
  n.text
rescue NoMethodError => e
  e.message.end_with?("<<' for nil")
end

def joined(n)
  n.text.concat("d")
  n.text
rescue NoMethodError => e
  e.message.end_with?("concat' for nil")
end

def upcased(n)
  n.text.upcase!
  n.text
rescue NoMethodError => e
  e.message.end_with?("upcase!' for nil")
end

def replaced(n)
  n.text.replace("z")
  n.text
rescue NoMethodError => e
  e.message.end_with?("replace' for nil")
end

def cleared(n)
  n.text.clear
  n.text
rescue NoMethodError => e
  e.message.end_with?("clear' for nil")
end

def answer(n)
  (n.text << "e").size
rescue NoMethodError => e
  e.class
end

# An argument that runs code can rebind the attribute before the call
# runs. Such a call is compiled as it was: the mutator changes the String
# the reader gave before the argument ran, whatever the attribute holds
# after it.

def swapped(n)
  old = n.text
  n.text << n.swap
  [n.text, old]
end

live = Note.new
p appended(live)
p joined(live)
p upcased(live)
p answer(live)
p replaced(live)
p cleared(live)
p live.text

gone = Note.new
gone.drop
p appended(gone)
p joined(gone)
p upcased(gone)
p answer(gone)
p replaced(gone)
p cleared(gone)
p gone.stamp
p gone.text

folder = Folder.new
p folder.note.stamp
p filed(folder)
folder.note.drop
p filed(folder)

set = Note.new
set.text = nil
p appended(set)
p set.text
set.text = +"x"
p appended(set)

kept = Note.new
p swapped(kept)
