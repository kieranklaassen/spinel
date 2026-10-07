# An exception of a class of the program's own, rescued and kept in an Array,
# answers is_a?, kind_of?, instance_of? and a `when` arm for that class. It
# answered false to each and took the else arm: the test compared the class id
# of the boxed value, and a raised exception is boxed as an Exception that
# carries its class by name. One never raised was right, and still is.
class Coded < StandardError
  def initialize(code)
    @code = code
    super("code #{code}")
  end
end
class Plain < StandardError; end
class Deeper < Plain; end
module App
  class Error < StandardError; end
  def self.kind(x) = x.is_a?(Error)
end

kept = []
begin; raise Plain, "a"; rescue StandardError => e; kept << e; end
begin; raise Deeper, "a"; rescue StandardError => e; kept << e; end
begin; raise App::Error, "a"; rescue StandardError => e; kept << e; end
begin; raise KeyError, "a"; rescue StandardError => e; kept << e; end
begin
  raise Coded.new(3)
rescue Coded => e
  kept << e
end
kept << Plain.new("never raised") << 3

p kept.map { |x| x.is_a?(Plain) }
p kept.map { |x| x.kind_of?(Deeper) }
p kept.map { |x| x.instance_of?(Plain) }
p kept.map { |x| x.is_a?(Coded) }
p kept.map { |x| App.kind(x) }
p kept.all? { |x| x.is_a?(StandardError) }
names = kept.map do |x|
  case x
  when Deeper then :deeper
  when Plain then :plain
  when App::Error then :app
  when Coded then :coded
  else :other
  end
end
p names

# What the test guards then runs on the value: a method and an attribute of
# the class, on one raised and on one never raised.
class Tagged < StandardError
  attr_reader :tag
  def mark!(t) = (@tag = t; self)
  def note = "tagged"
end
seen = [3]
begin; raise Tagged, "r"; rescue StandardError => e; seen << e; end
seen << Tagged.new("n")
seen.each { |x| puts "#{x.note} #{x.message}" if x.is_a?(Tagged) }
seen.each { |x| p x.tag if x.is_a?(Tagged) }
seen.each { |x| x.mark!("t-" + x.message) if x.instance_of?(Tagged) }
seen.each do |x|
  case x
  when Tagged then p x.tag
  else p x
  end
end
