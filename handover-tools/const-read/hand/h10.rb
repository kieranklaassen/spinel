module M
  LIMIT = "M"
end
module N
  LIMIT = "N"
end
class P
  include N
end
class C < P
  include M
  def lim = LIMIT
end
class P
  include M
  LIMIT = "P"
end
class D < P
  include M
  include N
  def lim = LIMIT
end
p C.new.lim
p D.new.lim
p C.ancestors.first(5)
p D.ancestors.first(4)
