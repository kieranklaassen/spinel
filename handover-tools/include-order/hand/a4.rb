module A
  NAME = "A"
  def who = NAME
end
module B
  NAME = "B"
  include A
  def who = NAME
end
class C
  NAME = "C"
  include B
  include A
end
p C.new.who
