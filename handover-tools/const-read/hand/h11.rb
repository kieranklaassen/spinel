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
module M6
  include M1, M0
end
class R
  include M5, M2
  def lim = LIMIT
end
class Q
  include M2, M5
  def lim = LIMIT
end
class T
  include M6
  include M5
  def lim = LIMIT
end
p R.new.lim
p Q.new.lim
p T.new.lim
