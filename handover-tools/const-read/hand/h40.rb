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
  include M2
  include M5
  include M2
  include M5
  def lim = LIMIT
  def self.lim = LIMIT
  LIM = -> { LIMIT }
end
class S < R
  include M5
  def lim2 = LIMIT
  def blk = [1].map { LIMIT }
end
p R.new.lim, R.lim, R::LIM.call, S.new.lim2, S.new.blk
