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
