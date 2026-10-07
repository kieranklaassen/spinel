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
  def self.include(*mods)
    puts "no"
  end
  include M2
  include M5
  def lim = LIMIT
end
p((R.new.lim rescue "none"))
