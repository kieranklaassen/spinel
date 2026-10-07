# `in String => s` binds s to the subject itself, here another object's
# String read through its reader. s holds a reader's String by a handle and
# the subject has none to give, with --share-strings as without: s would
# take a copy and the append would not reach `other.text`.
class Page
  attr_reader :text
  def initialize(t)
    @text = +t
  end
end
k = Page.new("k")
other = Page.new("zz")
s = k.text << "a"
case other.text
in String => s
  s << "!"
end
p other.text, s
