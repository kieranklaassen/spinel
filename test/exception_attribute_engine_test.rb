# An exception class whose initialize stands under a test of the engine. The
# compiler settles the test and drops the arm before it reads the class, so
# it cannot know the class has no initialize: the class is built as it was,
# and the attribute the dropped initialize stores reads as it did.
class Counted < StandardError
  attr_accessor :count
  if RUBY_ENGINE == "ruby"
    def initialize(msg = nil)
      super
      @count = 0
    end
  end
end

e = Counted.new("made")
p e.count
begin
  raise Counted, "raised"
rescue Counted => x
  p x.count, x.message
end
