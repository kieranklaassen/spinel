# A `&.` call to a method only a MatchData or an Enumerator answers, on a
# value read out of a container: the handle's answer, and nil for a nil.
m = ["xab-cd".match(/a(?<b>b)-(?<c>c)/), 0][ARGV.size]
z = [nil, 0][ARGV.size]
p m&.begin(0), m&.end(:b), m&.offset(1), m&.byteoffset(2)
p z&.begin(0), z&.end(:b), z&.offset(1), z&.byteoffset(2)
p m&.pre_match, m&.post_match, m&.captures, m&.string
p z&.pre_match, z&.post_match, z&.captures, z&.string
p m&.begin(2)&.succ, z&.begin(2)&.succ
p m&.captures&.size, m&.pre_match&.upcase, m&.offset(2)&.sum
p "#{m&.begin(0)}-#{z&.begin(0)}-#{m&.post_match}"
a = m&.end(0)
b = z&.end(0)
p a, b
m&.begin(0)
z&.pre_match

def spans(v) = [1, 2].map { |g| v&.offset(g) }
p spans(m), spans(z)

e = [[4, 5].each, 0][ARGV.size]
n = [nil, 0][ARGV.size]
p e&.with_index(1)&.to_a, n&.with_index(1)&.to_a
p e&.with_index&.map { |x, i| x * i }, n&.with_index&.to_a
p e&.next_values, e&.peek_values, n&.next_values, n&.peek_values

# any other value still raises
begin
  [7, nil][ARGV.size]&.begin(0)
rescue NoMethodError => ex
  p ex.class
end
