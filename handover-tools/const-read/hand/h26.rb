module A
  LIMIT = "A"
end
module B
  LIMIT = "B"
end
module AB
  include A
  include B
end
class Root
  include A
end
class P < Root
  include B
end
class C < P
  include AB
  include A
  def lim = LIMIT
end
class E < Root
  include AB
  def lim = LIMIT
end
p C.new.lim
p E.new.lim
p C.ancestors.first(3), E.ancestors.first(3)
