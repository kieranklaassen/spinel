module Conf
  LIMIT = 1
end
class Base
  include Conf
end
class Sub < Base
  def limit = LIMIT
end
p Sub.new.limit
class Other
  LIMIT = 2
  def limit = LIMIT
end
p Other.new.limit, Sub.new.limit
