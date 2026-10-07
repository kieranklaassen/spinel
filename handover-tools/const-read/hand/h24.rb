module M0
  LIMIT = 1
end
module M1
  LIMIT = 2
end
module M2
  include M0
  include M1
end
module M5
  include M0
end
class String
  include M1
end
class S < String
  include M2
  include M5
  def lim = LIMIT
end
p S.new.lim
p S.ancestors.first(4)
