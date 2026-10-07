<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
h = {}
%w[a b a].each { |w| h[w] ||= +""; h[w] << "!" }
p h.to_a
```

`spinel diff t.rb` on master (26d456ec1); with this commit it says `same`:

```
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[["a", "!!"], ["b", "!"]]
+[["a", ""], ["b", ""]]
```

Written `h[w] = +""` it is right in the default build. #____ lists the value of `h[k] ||= v` and `h[k] &&= v` as a store under `--share-strings`; this lists it in the default build too.

**The choice.** CONTRIBUTING.md asks that a route that copies a String in silence be refused, and that no per-route sharing rule be added. `h[k] ||= v` is the store `h[k] = v` that the default build already shares, under another spelling: this adds no holder, container or leaf, and where `c[k] = v` is not shared today `c[k] ||= v` is not either. The other way is to refuse the or-assigned store in the default build. That would stop the 1,008 programs below that this makes right, and right programs whose key is already there (`g = {a: +"x"}; g[:a] ||= +"n"; g[:a] << "w"`), while the same lines written with `=` build and are right. This pull request takes the first; which of the two is yours to say.

**It carries two refusals master makes for `=` over to `||=`**, because both checks read the list of stores. A method that or-assigns a String into a container its caller passed is refused as it is with `=` ("a String a method stores into an Array or Hash its caller passed it is mutated in place through the caller's container"); the program met here prints a wrong answer on master. The other takes right programs:

```ruby
h = {}
h[:list] ||= []
h[:name] ||= +"n"
h.each_value { |v| v << "item" if v.is_a?(Array) }
p h      # master and CRuby: {list: ["item"], name: "n"}
```

```
spinel: t.rb:3: a String stored in a Hash is passed to an appending value block: a String is not yet shared by reference through a Hash's values. Append to the String before storing it in the Hash.
```

Master refuses it at that line in those words when it is written with `=`. The check cannot tell whether the append lands on the String: here it lands only on the Array, so a program that is right on master stops building. Where it does land (`h[:name] ||= +"n"; h.each_value { |v| v << "!" }`) master prints `{name: "n"}` in silence. Of 12 programs written to meet it, 11 are refused, 8 right on master and 3 wrong, and master refuses all 11 `=` twins at the same line. Keeping the `||=` value off the list that check reads would give the 8 back and send the 3 back to a silent wrong answer, so the check is not narrowed. With `--share-strings` none of the 12 is refused and all are right.

Against CRuby 3.3.6 on master 26d456ec1: of 2,814 generated programs 1,008 go from wrong to right (1,254 right before, 2,262 after) and none that is right answers differently or stops building; the 552 left are `=` programs and `||=` / `&&=` programs that print the lines of their `=` twin. Of 234 written by hand, 54 go from wrong to right, the four refused are wrong on master (three by the value-block check, one by the check for a caller's container), and none that is right changes. One raise becomes the right one: `h = Hash.new; h["j"] &&= +""; t = h["k"]; t.concat("3")` raises NoMethodError as CRuby does, where master raises FrozenError.

The test moves from `test/share/` to `test/`, where it runs in both builds.

## `make gate` (on this branch merged with current master)

```
not run in full here (it runs on the Mac before anything goes upstream). In the cloud, above the two it depends on, on master 26d456ec1: make share-strings-test passes; tools/gate.rb check passes (no Ruby 4.0 here, so .expected was not compared).
cident: 6347 identical, 5 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against 26d456ec1): the four that print the compiler's revision and this test. Taken with the guard's test set aside, because master's compiler does not finish it.
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints Arrays, Strings, booleans and nil)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #____ (An index `||=` stores the shared String handle under --share-strings), which depends on the guard
