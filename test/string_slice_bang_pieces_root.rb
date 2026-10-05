# The head and the tail of a String are both held while slice! joins them.
# slice! with an Integer, a start and a length, or a Range rebuilt the
# receiver from two new Strings in one C expression, and the one made first
# was held by nothing while the other was allocated. Each round slices
# through every form, as a statement, with the removed part taken, through
# a second name and by a boxed index, and counts the results that are not
# Ruby's.
W = "qrstuvwxyz"
bad = 0
300.times do |i|
  n = 2 + i % 3
  w = W + i.to_s
  s = W + i.to_s
  s.slice!(n)
  bad += 1 unless s == w[0, n] + w[n + 1..]
  s = W + i.to_s
  s.slice!(n, 3)
  bad += 1 unless s == w[0, n] + w[n + 3..]
  s = W + i.to_s
  s.slice!(n..5)
  bad += 1 unless s == w[0, n] + w[6..]
  s = W + i.to_s
  q = s.slice!(n)
  bad += 1 unless q == W[n] && s == w[0, n] + w[n + 1..]
  s = W + i.to_s
  q = s.slice!(n, 3)
  bad += 1 unless q == W[n, 3] && s == w[0, n] + w[n + 3..]
  s = W + i.to_s
  q = s.slice!(n..5)
  bad += 1 unless q == W[n..5] && s == w[0, n] + w[6..]
  s = W + i.to_s
  t = s
  t.slice!(n)
  bad += 1 unless s == w[0, n] + w[n + 1..] && s.equal?(t)
  s = W + i.to_s
  t = s
  q = t.slice!(n, 3)
  bad += 1 unless q == W[n, 3] && s == w[0, n] + w[n + 3..] && s.equal?(t)
  k = [n, "x"][0]
  s = W + i.to_s
  q = s.slice!(k)
  bad += 1 unless q == W[n] && s == w[0, n] + w[n + 1..]
  k = [(n..5), 1][0]
  s = W + i.to_s
  q = s.slice!(k)
  bad += 1 unless q == W[n..5] && s == w[0, n] + w[6..]
end
p bad
s = W + "!"
p s.slice!(2, 3), s
s.slice!(-3..)
p s
s.slice!(1)
p s
# With longer pieces a plain run loses them as well. The removed parts are
# kept, so the heap grows from round to round.
big = 0
keep = []
a = "ab" * 2_000
1_000.times do |i|
  s = a + "<#{i}>" + a
  keep << s.slice!(4_000, i.to_s.size + 2)
  big += 1 unless s == a + a
end
keep.each_with_index { |q, i| big += 1 unless q == "<#{i}>" }
p big, keep.size
