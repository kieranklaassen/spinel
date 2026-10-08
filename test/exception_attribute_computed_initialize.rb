# An exception class given its initialize by a name the text does not spell.
# The compiler cannot know the class has no initialize: the class is built
# as it was, and the attribute that initialize stores reads as it did.
class Counted < StandardError
  attr_accessor :count
  name = "initialize"
  define_method(name.to_sym) do |msg = nil|
    super(msg)
    @count = 0
  end
end

e = Counted.new("made")
p e.count
begin
  raise Counted, "raised"
rescue Counted => x
  p x.count, x.message
end
