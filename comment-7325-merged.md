Three programs answered as CRuby does before this was merged (a1586ee1) and do not on master now (344d83ad):

```ruby
p ("a".."zzzzzzzz").find { |s| s == "c" }
# CRuby 4.0.7 and e5e8f794: "c". Master: no output, memory grows without stopping.

p ("aaa"..."zz").min
# CRuby and e5e8f794: "aaa". Master: nil.

p ("99999999999999999998".."100000000000000000001").to_a
# CRuby and e5e8f794: the four members. Master: [].
```

The first and the third are the cases CodeRabbit's comments describe. Every traversal of a String range still rides its element array, so with the 4096 cut gone one that leaves early builds the whole range first; all-digit ends past 18 digits fall to the succ walk, which first compares the ends as bytes.

The second: `sp_srange_min_v` walks a range whose end is excluded and takes the least member, and with the walk corrected `("aaa"..."zz")` has no member. CRuby's `range_min` (range.c) does not walk: with no block and no count it compares the ends.

A fix for the three is coming as a pull request.
