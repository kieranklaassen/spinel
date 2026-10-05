I merged 5fb698cb1 with master fa08b100d and ran it on some prepend programs (Linux x86-64, gcc and clang, against CRuby 3.3.6 with `--enable-frozen-string-literal`).

What it cures here: 300 rounds of

```ruby
s = +"r#{i}"
t = s
t.prepend("a#{i}", "b#{i}")
```

abort under `SPINEL_GC_STRESS=2` on master and are right with this change at every level, with both compilers; and the operands now run in source order where master built with gcc ran the last one first.

Five programs go the other way. Each prints the first answer in CRuby and on master built with gcc, and the second with this change, built with gcc or with clang (master built with clang prints the second already):

```ruby
class W
  def initialize(t) = @t = t
  def to_s = (@t << "z"; "a")
end

s = +"s"; s2 = s
t = +"t"; t2 = t
p s.prepend(t, (t << "x"; "c"))               # "txcs"   with this change: "tcs"

s = +"s"; s2 = s
t = +"t"; t2 = t
p s.prepend(t, (t.replace("vv"); "e#{2}"))    # "vve2s"  with this change: "te2s"

s = +"s"; s2 = s
$g = +"g"
p s.prepend($g, ($g << "y"; "a"))             # "gyas"   with this change: "gas"

r = +"r"; r2 = r
u = +"u"; v = u
p r.prepend(u, (v << "x"; "a"))               # "uxar"   with this change: "uar"

s = +"s"; s2 = s
t = +"t"; t2 = t
w = W.new(t)
p s.prepend(t, "#{w}")                        # "tzas"   with this change: "tas"
```

The cause, as far as I can tell: the text of an argument String is read into its temp where the argument stands, and Ruby hands `prepend` the String itself and reads its text when the call runs, after every argument has been evaluated. So a later argument that appends to an earlier one, or replaces its contents, is not seen.
