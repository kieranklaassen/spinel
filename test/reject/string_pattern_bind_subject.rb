# A pattern binds the SUBJECT ITSELF to the local: the same String, not a
# copy. `s` holds a reader's String that is appended to, so it holds it by a
# handle; the plain String `line` has none to give, and a copy would part
# the two (the append below would not show in `line`). Refused, where the
# append was lost with nothing said.
class Page
  attr_reader :text
  def initialize
    @text = +"k"
  end
end
k = Page.new
line = +"zz"
s = k.text << "a"
case line
in String => s
  s << "!"
end
p line, s
