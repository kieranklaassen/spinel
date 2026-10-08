# An exception class with an `exception` of its own: a raise of the class by
# its name asks that method for the object, so what is raised is not known
# from the class's initialize alone. The class is built as it was.
class Counted < StandardError
  attr_accessor :count
  def self.exception(*args)
    e = new(*args)
    e.count = 0
    e
  end
end

begin
  raise Counted, "raised"
rescue Counted => x
  p x.count, x.message
end
