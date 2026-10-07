# The match registers hold the positions of 32 groups, and =~, a `when` arm,
# a match from a position and slice! kept the first sixteen: a group past
# the fifteenth read as "" at position 0, or as the match before.
s = "abcdefghijklmnopqrstuvwxyz"
s =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)/
p $~.to_a.size, $~.size, $~.to_a[15], $~.to_a[16], $~.to_a[20], $~.captures.size, $~.end(0), $~.post_match
case s
when /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)/
  p $~.to_a[16], $~.begin(20), $~.captures[19], $~.values_at(15, 16, 17)
end
t = +"abcdefghijklmnopqrstuvwxyz"
p t.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)/), $~.to_a[18], $~.end(17)
p s.match?(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)/)
s.match(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)/, 0)
x = (s =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)(u)(v)(w)(x)(y)(z)/)
# the widest pattern a literal may hold
s = "a" * 40
s =~ /(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)(a)/
p $~.size, $~.to_a[31], $~.begin(31), $~.to_a.size
