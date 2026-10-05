Three programs print CRuby's answer on master today and not on this head (5073df1e alone, and with #7328 on top):

```ruby
p ("a".."zzzzzzzz").find { |s| s == "c" }
# CRuby 4.0.7 and master: "c". Here: memory grows without bound.

p ("aaa"..."zz").min
# CRuby and master: "aaa". Here: nil.

p ("99999999999999999998".."100000000000000000001").to_a
# CRuby and master: the four members. Here: [].
```

The first and the third are the cases CodeRabbit's comments describe, seen here as a change from master. Every traversal of a String range still rides its element array, so with the 4096 cut gone one that leaves early builds the whole range first: of 276 one-line programs that leave a range of 10^11 members early and answer on master (`find`, `first(3)`, `any?`, `take_while`, `each` with a break and the like), 216 do not finish on #7328's head. All-digit ends past 18 digits fall to the succ walk, which first compares the ends as bytes.

The second has not been raised. `sp_srange_min_v` walks a range whose end is excluded and takes the least member; with the walk corrected `("aaa"..."zz")` has no member, so the answer is nil. CRuby's `range_min` (range.c) does not walk: with no block and no count it compares the ends.

A follow-up on top of #7328 is ready if it is wanted: a traversal that can leave early no longer builds the whole range, `min` is decided by the ends, and all-digit ends walk as numbers at any width.
