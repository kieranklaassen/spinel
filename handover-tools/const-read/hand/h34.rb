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
  def lim = LIMIT
end
puts "start"
class R
  include M5
end
p R.new.lim
