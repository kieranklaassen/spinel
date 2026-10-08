# slice_when read through inspect tests its block's value by Ruby's truth:
# an Integer, a Float and a Symbol are true even at 0, nil is false, and a
# value of more than one kind is tested as the boxed value it is.
a = [1, 2, 4, 9]
puts a.slice_when { |x, y| y - x - 1 }.to_a.inspect
puts a.slice_when { |x, y| y % 2 }.to_a.inspect
puts a.slice_when { |x, y| 0 }.to_a.inspect
puts a.slice_when { |x, y| (y - x - 1).to_f }.to_a.inspect
puts a.slice_when { |x, y| :s }.to_a.inspect
puts a.slice_when { |x, y| t = y - x; t - 1 }.to_a.inspect
puts (1..5).slice_when { |x, y| y % 2 }.to_a.inspect
s = a.slice_when { |x, y| y % 2 }.to_a.inspect
puts s

# nil beside an Integer, and the value of an && or an ||
puts a.slice_when { |x, y| (y - x) > 1 ? nil : 0 }.to_a.inspect
puts a.slice_when { |x, y| [x, y].sum > 5 && y }.to_a.inspect
puts a.slice_when { |x, y| y > 3 || nil }.to_a.inspect

# a comparison, a predicate and nil, as before
puts a.slice_when { |x, y| y > x + 1 }.to_a.inspect
puts a.slice_when { |x, y| y.zero? }.to_a.inspect
puts a.slice_when { |x, y| nil }.to_a.inspect
