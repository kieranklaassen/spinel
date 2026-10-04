# A bare `super` hands the initialize's own parameter to the member: the
# caller's String, which the member changed in place would copy.
class Tag < Struct.new(:text)
  def initialize(text)
    super
  end
end
t = Tag.new("a".dup)
t.text << "!"
p t.text
