def tick(v)
  puts "tick #{v}"
  v
end
p (tick(1)..tick(3)).sum
