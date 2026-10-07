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
module M9
  LIMIT = 9
end
class R
  include M2
  include M5
  def lim = LIMIT
end
module M5
  include M9
end
p R.new.lim
p R.ancestors.first(6)
