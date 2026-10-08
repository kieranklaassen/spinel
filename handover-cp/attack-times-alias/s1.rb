def pick(n, v) = n > 0 ? { a: 1 } : v
class String
  alias_method "*", "+"
end
begin
  p(pick(0, "ab") * pick(0, 2.5))
rescue TypeError => e
  puts e.message
end
