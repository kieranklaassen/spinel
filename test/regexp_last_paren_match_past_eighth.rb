# $+ is the last group that took part in the last match. It was read from
# the kept Strings one place off, so a ninth group answered the eighth, and
# a group past the ninth was never reached.
"abcdefghi" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)/
p $+
"abcdefgh" =~ /(a)(b)(c)(d)(e)(f)(g)(h)/
p $+
"abcdefghijkl" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/
p $+
"abcdefghi" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)?/
p $+
"ab" =~ /(a)(b)(c)?/
p $+
"ab" =~ /ab/
p $+
"zz" =~ /(a)/
p $+
"abcdefghi" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(z)?(i)/
p $+
"xa" =~ /(a)|(b)/
p $+
# after String#match, which keeps the Strings of nine groups
"abcdefghi".match(/(a)(b)(c)(d)(e)(f)(g)(h)(i)/)
p $+
