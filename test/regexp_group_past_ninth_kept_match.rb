# A program test/regexp_group_past_ninth.rb leaves alone: String#match hands
# $~ its Strings and not its positions, so a group past the ninth is not cut
# from the subject there. The tenth group took no part, and reads nil.
"xxabcdefghijk" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)/
"0123456789AB".match(/(0)(1)(2)(3)(4)(5)(6)(7)(8)(z)?(9)/)
p $9, $10, $~[10], Regexp.last_match(10), defined?($10)
