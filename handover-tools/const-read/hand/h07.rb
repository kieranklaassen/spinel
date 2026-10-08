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
class R
  include M5
  SEEN = LIMIT
  include M2
  def lim = LIMIT
end
p R::SEEN
p R.new.lim
