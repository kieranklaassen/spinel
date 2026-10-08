def pick(n, v) = n > 0 ? { a: 1 } : v
module R
  refine String do
    def *(o) = "r"
  end
end
using R
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
