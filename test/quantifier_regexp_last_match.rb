# any?, all?, none? and one? given a Regexp ask it of an element at a time and
# stop where the answer is known, so $~ is the last match CRuby made: any? and
# none? stop at the first match, all? at the first miss, one? at the second
# match. All the elements were asked, which left the last one's.
a = ["xb", "q", "yb"]
p a.any?(/(.)b/), $1
p a.none?(/(.)b/), $1
p a.all?(/(.)b/), $~
p a.one?(/(.)b/), $1
p ["q", "xb"].any?(/(.)b/), $1
p ["q", "xb"].none?(/(.)b/), $1
p ["xb", "yb"].all?(/(.)b/), $1
p ["xb", "q"].one?(/(.)b/), $~
p ["xb", "yb", "zb", "q"].one?(/(.)b/), $1
p ["q", "r"].any?(/(.)b/), $~
p ["q", "r"].none?(/(.)b/), $~
p ["q", "xb"].all?(/(.)b/), $~

# an empty Array asks nothing, so $~ stays what it was
"k9" =~ /k(\d)/
e = ["z"]
e.pop
p e.any?(/(.)b/), e.all?(/(.)b/), e.none?(/(.)b/), e.one?(/(.)b/), $1

# the answers themselves
w = ["ab", "cb", "d"]
p w.any?(/b/), w.all?(/b/), w.none?(/b/), w.one?(/b/)
p w.any?(/d/), w.all?(/./), w.none?(/z/), w.one?(/d/)
p w.any?(/z/), w.all?(/d/), w.none?(/d/), w.one?(/z/)
