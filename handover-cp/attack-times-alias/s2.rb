def pick(n, v) = n > 0 ? { a: 1 } : v
class Array
  alias_method "*", "+"
end
begin
  p(pick(0, [1, 2]) * pick(0, 2.5))
rescue TypeError => e
  puts e.message
end
