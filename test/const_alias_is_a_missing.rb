# A constant given a class by a path holds the program's class where the
# body the path names defines it. Elsewhere a const_missing of the program
# answers the path, with whatever it returns.
class Plain; end

class Conn
  class Inner; end
  def self.const_missing(name) = Integer
end

Missing = Conn::Plain
Held = Conn::Inner

p Plain.new.is_a?(Missing)
p Conn::Inner.new.is_a?(Held)
p 7.instance_of?(Held)
