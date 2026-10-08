def kind(v)
  case v
  when nil then "nil"
  when false then "false"
  when true then "true"
  else "other"
  end
end
a = [1, 2].empty?
puts kind(a)
puts kind(!a)
b = 3 > 5
case b
when nil then puts "nil"
when false then puts "false"
else puts "else"
end
case b
when nil, 0 then puts "nil or 0"
else puts "else"
end
x = case [1].frozen? when nil then "n" when true then "t" else "f" end
puts x
c = (3 > 5)
puts(case c when nil then "N" else "E" end)
puts(case c when NilClass then "NC" else "E" end)
puts(nil === c)
puts(case 0 == 1 when nil then "N" when false then "F" end)
