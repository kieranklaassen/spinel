def pick(n, v) = n > 0 ? { a: 1 } : v
s = +"ab"
s.define_singleton_method(:*) { |o| "single" }
begin
  p(pick(0, s) * pick(0, 2.5))
rescue TypeError, NoMethodError, ArgumentError => e
  puts "#{e.class}: #{e.message[0, 44]}"
end
begin
  p(pick(0, s) * pick(0, 2))
rescue TypeError, NoMethodError, ArgumentError => e
  puts "#{e.class}: #{e.message[0, 44]}"
end
