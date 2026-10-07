module Conf
  LIMIT = 1
end
class Other
  LIMIT = 2
end
class Base
  include Conf
end
class Sub < Base
  def limit = LIMIT
end
class Other
  def limit = LIMIT
end
p Sub.new.limit, Other.new.limit
