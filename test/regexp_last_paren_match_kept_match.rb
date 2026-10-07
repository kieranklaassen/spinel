# A program test/regexp_last_paren_match_past_eighth.rb leaves alone:
# String#match hands $~ its Strings and not its positions, so $+ reads the
# Strings there and not the positions of the match before.
"xxabcdefghijkl" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/
"0123".match(/(0)(1)(2)(z)?/)
p $+
