def pick(n, v) = n > 0 ? { a: 1 } : v
class String
  undef_method :*
end
begin
  p(pick(0, "ab") * pick(0, 2.5))
rescue NoMethodError, TypeError => e
  puts e.class
end
