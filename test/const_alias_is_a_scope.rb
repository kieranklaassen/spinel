# A bare constant inside a class or module is looked up in that body, then in
# what the class inherits or mixes in, before the program's own level: a name
# one of CRuby's own namespaces holds is not the program's constant there.
Status = Integer
module Process
  def self.status?(v) = v.is_a?(Status)   # Process::Status
end
p Process.status?(7)

E = Integer
class Calc
  include Math
  def e?(v) = v.is_a?(E)                  # Math::E, a Float
end
begin
  p Calc.new.e?(7)
rescue TypeError
  p false
end

# the program's own level reads the program's constant
p 7.is_a?(Status), 7.is_a?(E)

# the value of a write is read where the write stands: under `include Math`
# a bare DomainError is Math's, and so is Gauge::DomainError; neither
# constant holds the program's class
class DomainError < StandardError; end
module Gauge
  include Math
  ERR = DomainError                       # Math::DomainError
  def self.dom?(e) = e.is_a?(ERR)
end
p Gauge.dom?(DomainError.new("x")), DomainError.new("x").is_a?(Gauge::ERR)
J = Gauge::DomainError                    # Math's too, through Gauge
p DomainError.new("x").is_a?(J)
