module A; def who = "A"; end
module B; include A; def who = "B"; end
Point = Struct.new(:x) do
  def who = "S"
end
class C
  include B
  include A
end
p C.new.who, Point.new(1).who
