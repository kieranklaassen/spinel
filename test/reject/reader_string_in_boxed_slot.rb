# An ivar that holds nil until a setter gives it a String is a boxed slot,
# and the String read from it is changed in place: the change would reach a
# copy, so the program is refused by name where the C did not build.
class Note
  attr_accessor :text
  def initialize(text) = @text = text
end
s = +"q"
n = Note.new(nil)
n.text = s
n.text << "z"
p n.text, s
