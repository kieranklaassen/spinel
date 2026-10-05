# A bare `super` hands the initialize's own parameter to the member, and
# the member's String is changed in place: refused at the `super`.
class Tag < Struct.new(:text)
  def initialize(text)
    super
  end
end
t = Tag.new("a".dup)
t.text << "!"
p t.text
