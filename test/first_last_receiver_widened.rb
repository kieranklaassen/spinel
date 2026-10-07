# first / last on a parameter that is an Array in the first call and another
# value in a later one are that value's own first and last
def show(v) = v.is_a?(Array) ? v.map { |x| show(x) } : (v.is_a?(Range) ? [v.first, v.last] : v)
p show([(1..2), 1])

# a Hash's first is its first pair
def heads(v)
  if v.is_a?(Array)
    v.map { |x| heads(x) }
  elsif v.is_a?(Hash)
    v.first
  else
    v
  end
end
p heads([{ 1 => 2, 3 => 4 }, 5])

# the answers are used as numbers
def walk(v, d) = v.is_a?(Array) ? v.sum { |x| walk(x, d + 1) } : (v.is_a?(Range) ? v.first + v.last + d : 0)
p walk([(1..2), 1, [(5..6)]], 0)

# a Float Range and a String Range
def ends(v) = v.is_a?(Array) ? v.map { |x| ends(x) } : [v.first, v.last]
p ends([(1.5..2.5), ("a".."c")])

# collected through a block that only walks
def gather(v, acc)
  if v.is_a?(Array) && v.size == 2
    v.each { |x| gather(x, acc) }
  else
    acc << v.last
  end
  acc
end
p gather([(3..4), [7, 8, 9]], [])

# an Array all the way down is still read by its ends
def tips(v) = v.size == 2 && v[0].is_a?(Array) ? v.map { |x| tips(x) } : [v.first, v.last]
p tips([[1, 2, 3], [4, 5]])
p tips([[], [nil]])

# a value with no first says so
def bad(v) = v.is_a?(Array) ? v.map { |x| bad(x) } : v.first
begin
  bad(["abc", 1])
  puts "no raise"
rescue NoMethodError
  puts "NoMethodError"
end
begin
  bad([5, [6]])
  puts "no raise"
rescue NoMethodError
  puts "NoMethodError"
end
