LIMIT = 0
module M0
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
module Z
  LIMIT = 9
end
class R
  include M2
  include M5
  def lim = LIMIT
end
class Q
  include M5
  include M0
  def lim = LIMIT
end
p R.new.lim
p Q.new.lim
