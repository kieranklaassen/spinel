# CRuby runs a method of an exception class on its own: the class's `new`,
# initialize_copy where one is copied, backtrace and set_backtrace where one
# is raised, the class's === where an arm matches it. Where such a method
# stores a zero the attribute reads that zero, so only a class that holds
# attributes and nothing else has its attributes nil until set.
class Made < StandardError
  attr_accessor :count
  def self.new(m = nil)
    e = allocate
    e.count = 0
    e
  end
end
p Made.new("m").count

class Copied < StandardError
  attr_accessor :count
  def initialize_copy(o)
    super
    @count = 0
  end
end
p Copied.new("z").dup.count

class Traced < StandardError
  attr_accessor :count
  def backtrace
    @count = 0
    super
  end
end
class Stamped < StandardError
  attr_accessor :count
  def set_backtrace(b)
    @count = 0
    super
  end
end
class Matched < StandardError
  attr_accessor :count
  def self.===(o)
    o.count = 0 if o.respond_to?(:count=)
    super
  end
end
kept = []
begin
  raise Traced, "r"
rescue Traced => e
  p e.count, e.message
end
begin
  raise Stamped, "t"
rescue Stamped => e
  p e.count, e.message
end
begin
  raise Matched, "q"
rescue Matched => e
  p e.count, e.message
end
begin
  raise Traced, "s"
rescue StandardError => e
  kept << e
end
kept.each { |v| p v.count if v.respond_to?(:count) }

# beside them, a class with attributes and nothing else
class Plain < StandardError; attr_accessor :count, :at; end
p Plain.new("m").count
begin
  raise Plain, "p"
rescue Plain => e
  p e.count, e.at, e.message
  e.count = 3
  p e.count
end
