# A `&.` call on what a boxed MatchData or Enumerator answers under `&.`.
# The first call's node kept the handle's own type from the question its
# emitter asked, so the second call took the typed Array or String arm on
# the boxed value and the C did not compile.
m = ["xab-cd".match(/a(?<b>b)-(?<c>c)/), 0][ARGV.size]
z = [nil, 0][ARGV.size]
p m&.captures&.size, z&.captures&.size
p m&.captures&.join("-"), m&.captures&.empty?, m&.captures&.include?("b")
p m&.captures&.map(&:upcase), m&.captures&.to_a, m&.captures&.size&.succ
p m&.string&.size, m&.string&.bytesize, m&.string&.start_with?("x")
p m&.string&.chars, m&.string&.to_sym, z&.string&.size
p m&.pre_match&.length, m&.pre_match&.empty?, m&.post_match&.to_sym
p m&.offset(1)&.size, m&.begin(1)&.to_s, m&.end(1)&.zero?, z&.begin(1)&.to_s

e = [[4, 5].each, 0][ARGV.size]
n = [nil, 0][ARGV.size]
p e&.with_index(1)&.to_a, n&.with_index(1)&.to_a
p e&.with_index&.to_a, e&.with_index(1)&.size, e&.next_values&.size

# the first call alone, as a receiver of a `.`, and through a local
p m&.captures, m&.captures.size, m&.string.size
c = m&.captures
p c&.size, c&.first&.upcase
def spans(v) = [1, 2].map { |g| v&.offset(g)&.size }
p spans(m), spans(z)
p "#{m&.string&.size}-#{z&.string&.size}"

# read out by an index, the first `&.` alone did not build; a `.` call's
# value is the handle's own answer and keeps its type
xs = ["hello".match(/l+/), 0]
p xs[0]&.pre_match, xs[0]&.string&.size, xs[0]&.pre_match + xs[0][0]
p xs[0].string == xs[0].pre_match + "llo"
