# A Symbol Range literal walks the names String#upto walks.
#
# (:a..:e) is walked by name: String#succ from the begin until the end is
# met or the name grows past the end's length. That is the last of the
# cases String#upto has, and it was taken for all of them:
#
#   * a begin that sorts after the end walks nothing
#   * two names of one character walk every character between
#   * two names of digits walk the numbers between, at the begin's width
#   * a begin that is the end's successor walks nothing
#   * the walk stops at the end's successor, which a shorter name may reach
#
# Names that are not ASCII take String#upto's walk too.
#
# The first twelve lines were wrong in a plain run, and the last one. The
# others were right.

p (:y..:ab).to_a             # "y" sorts after "ab"
p (:b..:a).to_a
p (:zz..:b).to_a
p (:Zy..:AAb).to_a
p (:Y..:b).to_a              # one character each: the characters between
p (:"10"..:"9").to_a         # digits: by number
p (:"1"..:"010").to_a
p (:aa..:z).to_a             # the begin is the end's successor
p (:"z.0"..:"z.09").to_a     # "z.9" steps to "z.10", the end's successor
p (:x..:ab).include?(:z)
p (:b..:a).map(&:to_s)
n = 0
(:y..:ab).each { n += 1 }
p n

p (:a..:e).to_a
p (:a...:d).to_a
p (:a...:a).to_a
p (:"+"..:"0").to_a
p (:"08"..:"11").to_a
p (:"9"...:"12").to_a
p (:az..:bc).to_a
p (:a..:bb).to_a.size
p (:"a-"..:"b+").to_a.size
p (:ab..:ab).to_a
p (:ab...:ab).to_a
puts (:"aα"..:"aε").map(&:to_s).join(" ")   # not ASCII
puts (:"ε"..:"α").to_a.size                 # "ε" sorts after "α"
