## What this changes

```ruby
def grow(x)
  x << "!"
end
s = +"ab"
i = 0
while i < s.length
  grow(s) if i < 3
  i += 1
end
p i, s
```

printed `2` and `"ab!!"`. CRuby prints `5` and `"ab!!!"`.

```
spinel diff: output-diff
  program: grow.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-5
-"ab!!!"
+2
+"ab!!"
```

`emit_while` reads a String local's length once ahead of the loop unless the loop assigns the local or names it under one of 32 mutators. That list is of what does change a String, so each road it does not spell was a wrong loop count, and nothing failed: a method appending to its parameter, a second name, an Array, a Hash, an object or a lambda holding the String, `chop!`, `succ!`, `rstrip!`, `s, n = ...`, `force_encoding` through another holder.

The test is turned round. The length is read ahead only where nothing in the loop can change a String: the loop is one `hc_node_ok` already sees through (it runs no code), with String reads under names the program has not redefined, a read of a Hash kind that has no default block, a `return` and a nested loop taken too. A name missing from this list costs a read of the length at each test, never an answer.

Chosen against: keeping the read wherever the local's slot is a plain one that the loop hands to no call. That keeps every hoist in the tests, but a plain String is changed in place through any other holder (`t = s`, then `t.force_encoding("BINARY")` in the loop: 2 passes for 4), so the slot proves nothing.

Checked, against master 2f204adb:

- `test/while_length_changed.rb`: 12 of its 18 lines are wrong on master, all right on the branch with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2.
- `make cident`: 6,313 identical, 28 differ: the two new tests and 26 programs that share seven loops, which now read the length at each test. packages/uri/uri.rb 138 and 164 append to another String; packages/cgi/cgi.rb 194 and packages/optparse/optparse.rb 213 call a method of the program; test/hash_local_not_a_strbuf.rb 13 stores into a Hash; uri.rb 264 and 294 lose it only in the eight net/http tests, which use threads.
- No benchmark's C changes. optcarrot's C is identical.
- The loop the hoist is for keeps it: `tight_ascii.rb` below still reads the length once, and runs in 0.13 s on both trees and 0.52 s with the hoist off (timed at master 06064727).
- callgrind for the three loop shapes that now re-read (programs below): `uri_decode.rb` 1,354,096,778 -> 1,435,994,978 Ir (+6.05%), `cgi_entity.rb` 1,072,835,886 -> 1,107,652,581 Ir (+3.25%), `hash_store.rb` 886,650,283 -> 965,485,825 Ir (+8.89%).
- scale-test: 1.71x, 4.74x, 6.06x and 4.18x on both trees (at master 06064727).

Left alone:

- A loop that calls a method of the program, appends to another String or stores into a Hash reads the length at each test even where none of that reaches the String, and so does every loop of a program that uses threads or finalizers (another thread can append at the loop's poll). That is the cost above.
- `setbyte` that changes how many characters there are, `capitalize!` and `swapcase!` on "ß", and a method added to String that changes `self` still give a wrong count, with the read hoisted or not.

<details><summary>The four programs</summary>

```ruby
# tight_ascii.rb
s = "abcdefghij" * 100
tot = 0
200_000.times do
  i = 0
  while i < s.length
    tot += s.getbyte(i)
    i += 1
  end
end
p tot
```

```ruby
# uri_decode.rb
require "uri"
src = "a%20b+c%2Fd" * 1000
n = 0
300.times do
  n += URI.decode_www_form_component(src).length
end
p n
```

```ruby
# cgi_entity.rb
require "cgi"
src = "x &#x4D2; y &#x1F600; z " * 500
n = 0
200.times do
  n += CGI.unescapeHTML(src).length
end
p n
```

```ruby
# hash_store.rb
def parse(serialized)
  out = {}
  i = 0
  s = serialized.to_s
  while i < s.length
    out[s[i, 1].to_s] = i.to_s
    i = i + 1
  end
  out
end
src = "abcdefghijklmnopqrstuvwxyz" * 40
n = 0
2000.times do
  n += parse(src).length
end
p n
```

</details>

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`while_length_changed` is written from CRuby 3.3.6; its 4.0 run is owed)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: # (the pull request of the commit below this one: the read ahead of the loop only where the first test makes it)
