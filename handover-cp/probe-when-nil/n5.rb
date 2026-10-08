def viablk = [1].empty?
def maybe(x)
  if x > 3
    v = x > 5
  end
  v
end
if ARGV.size > 3
  q = 3 > 5
end
begin
  rv = Integer("zz") > 3
rescue ArgumentError
end
d = 3 > 5
puts(case q when nil then "q nil" when false then "q false" else "q true" end)
puts(case rv when nil then "rv nil" when false then "rv false" else "rv true" end)
puts(case d when nil then "d nil" when false then "d false" else "d true" end)
puts(case maybe(1) when nil then "m nil" when false then "m false" else "m true" end)
puts(case maybe(4) when nil then "m nil" when false then "m false" else "m true" end)
puts(case viablk when nil then "v nil" when false then "v false" else "v true" end)
puts(case 3 > 5 when nil then "c nil" when false then "c false" else "c true" end)
p q
p rv
p maybe(1)
p q.nil?
p maybe(1).nil?
p q == nil
puts "unset" if q.nil?
puts (q ? "t" : "f")
