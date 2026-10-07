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
P = Class.new do
  include M2
  include M5
end
class R < P
  include M5
  def lim = LIMIT
end
p R.new.lim
