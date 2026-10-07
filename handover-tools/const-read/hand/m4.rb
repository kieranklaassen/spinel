module Conf
  LIMIT = 1
end
class Base
  include Conf
end
class Sub < Base
  def limit = LIMIT
  def twice = LIMIT * 2
end
class Other
  LIMIT = 2
end
class Third < Other
  LIMIT = 3
  def limit = LIMIT
end
class Fourth < Other
  def limit = LIMIT
end
p Sub.new.limit, Sub.new.twice, Third.new.limit, Fourth.new.limit
