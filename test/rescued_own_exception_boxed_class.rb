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
[Plain, Deeper, App::Error, KeyError].each do |k|
  begin
    raise k, "a"
  rescue StandardError => e
    kept << e
  end
end
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
