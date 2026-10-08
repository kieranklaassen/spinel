def pick(n, v) = n > 0 ? { a: 1 } : v
module Twice
  def twice(o) = self + self
  alias * twice
end
class String
  include Twice
end
begin
  p(pick(0, "ab") * pick(0, 2.5))
rescue TypeError, NoMethodError, ArgumentError => e
  puts "#{e.class}: #{e.message[0, 44]}"
end
begin
  p(pick(0, "ab") * pick(0, 2))
rescue TypeError, NoMethodError, ArgumentError => e
  puts "#{e.class}: #{e.message[0, 44]}"
end
