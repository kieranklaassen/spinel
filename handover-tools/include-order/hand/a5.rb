module A; def who = "A"; end
class P
  NAME = "P"
  def who = NAME
end
module B; include A; end
class C < P
  include B
end
class D < P
  NAME = "D"
end
class P
  include A
end
class D
  include B
  include A
end
p C.new.who, D.new.who
