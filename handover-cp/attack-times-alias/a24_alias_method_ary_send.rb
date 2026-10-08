def pick(n, v) = n > 0 ? { a: 1 } : v
Array.send(:alias_method, :*, :+)
begin
  p(pick(0, [1, 2]) * pick(0, 2.5))
rescue TypeError, NoMethodError, ArgumentError => e
  puts "#{e.class}: #{e.message[0, 44]}"
end
begin
  p(pick(0, [1, 2]) * pick(0, 2))
rescue TypeError, NoMethodError, ArgumentError => e
  puts "#{e.class}: #{e.message[0, 44]}"
end
