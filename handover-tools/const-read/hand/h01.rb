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
module Hook
  def self.included(base)
    puts base.new.lim
  end
end
class R
  def lim = LIMIT
  include M2
  include Hook
  include M5
end
p R.new.lim
