# The text of a Float range is made from two Strings, the lower bound's and
# the upper bound's, and nothing held the first while the second was made. A
# collection on the second freed the first and the second took its place:
# (4925.5..4926.5).to_s answered "4926.5..4926.5" in a plain run.

keep = []
i = 0
while i < 5000
  keep << ((i + 0.5)..(i + 1.5)).to_s
  i += 1
end
bad = []
keep.each_with_index { |s, k| bad << s unless s == "#{k + 0.5}..#{k + 1.5}" }
p bad

# every spelling of the text, and an Integer written as one bound
r = [(0.25..1.75), :a][0]
2.times do |i|
  puts ((i + 0.5)..(i + 1.5)).to_s
  puts ((i + 0.5)...(i + 1.5)).inspect
  puts "#{(i + 0.25)..(i + 1.75)}"
  puts ((i + 0.5)..(i + 2)).inspect
  puts r.inspect, r.to_s
end
p (-1.5..2.5), (1.0e20..1.0e21), (-0.0..0.0)

# one bound written is one String
puts (0.5..).inspect, (..1.5).inspect, (0.5...).to_s
