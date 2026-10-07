# Range#inspect of a String range quotes both bounds, two new Strings, and
# nothing held the first while the second was made: under SPINEL_GC_STRESS=2
# ("alpha".."omega").inspect printed freed bytes for "alpha".

r = ("alpha".."omega")
x = [("c".."d"), :a][0]
2.times do
  puts r.inspect
  puts ("a".."b").inspect, ("a"..."b").inspect
  puts x.inspect
  p r, x
end

# one bound written is one String
puts ("a"..).inspect, (.."b").inspect

# to_s quotes nothing and makes one String
puts r.to_s, x.to_s
