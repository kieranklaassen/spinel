# The head and the tail of a String are both held while slice! joins them.
# slice! with an Integer, a start and a length, or a Range rebuilt the
# receiver from two new Strings in one C expression, and the one made first
# was held by nothing while the other was allocated. Each round slices
# through every form, as a statement, with the removed part taken, and
# through a second name, and counts the results that are not Ruby's.
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
end
p bad
s = W + "!"
p s.slice!(2, 3), s
s.slice!(-3..)
p s
s.slice!(1)
p s
