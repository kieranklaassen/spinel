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
module T
  include M2
  include M5
  def lim = LIMIT
  def self.seen = LIMIT
end
class R
  include M5
  include T
end
p R.new.lim
p T.seen
