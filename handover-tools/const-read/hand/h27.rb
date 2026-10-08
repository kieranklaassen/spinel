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
class Bo < BasicObject
  include M2
  include M5
  def lim = LIMIT
end
p Bo.new.lim
