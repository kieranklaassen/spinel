module M
  LIMIT = "M"
end
module N
  LIMIT = "N"
end
module MN
  include M
  include N
end
class Root
end
class P < Root
end
class C < P
  include MN
  include M
  def lim = LIMIT
end
class Root
  include N
end
class F < P
  include MN
  def lim = LIMIT
end
p C.new.lim
p F.new.lim
p C.ancestors.first(4), F.ancestors.first(4)
