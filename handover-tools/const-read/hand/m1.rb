class Base
  LIMIT = 1
end
class Other
  LIMIT = 2
end
class Sub < Base
  def limit = LIMIT
  def self.lim = LIMIT
end
p Sub.new.limit, Sub.lim
