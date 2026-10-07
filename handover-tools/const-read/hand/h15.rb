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
  def self.method_added(n)
    puts new.lim if n == :other
  end
  def lim = LIMIT
  include M2
  def other = 1
  include M5
end
p R.new.lim
