<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
h = {}
%w[a b a].each { |w| h[w] ||= +""; h[w] << "!" }
p h.to_a
```

With `--share-strings` master prints `[["a", ""], ["b", ""]]`; CRuby and this print `[["a", "!!"], ["b", "!"]]`. (`spinel diff` takes no compiler flag; for the default build it reports the same two lines.) Written `h[w] = +""` it is right under the flag. The walks that list a container's stores did not know the value of an IndexOrWriteNode or an IndexAndWriteNode, so it went into the boxed slot as a plain String; under the flag it is now listed as the last argument of `[]=` is. That completes the flag's own listing for a node it missed; it adds no sharing rule. The generated C without the flag is unchanged.

**What it refuses.** Master's check for a method that stores a String into a container its caller passed reads the same list, so `def go(c); (c[0] ||= "ab".dup) << "1"; end` is now refused under the flag, in master's sentence: "a String a method stores into an Array or Hash its caller passed it is mutated in place through the caller's container". Of 2,814 generated programs compiled with the flag, 26 that master builds are refused this way: 24 print a wrong answer on master and 2 are right, both of those refused by master at the same line when written with `=`. 978 of the 2,814 go from wrong to right and none from right to wrong.

## `make gate` (on this branch merged with current master)

```
not run in full here (it runs on the Mac before anything goes upstream). In the cloud, above the guard on master 26d456ec1: make share-strings-test passes; tools/gate.rb check passes (no Ruby 4.0 here, so .expected was not compared).
cident: 6347 identical, 4 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against 26d456ec1): the four that print the compiler's revision. Taken with the guard's test set aside, because master's compiler does not finish it.
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints Arrays, Strings, booleans and nil)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #____ (the guard: A container that stores many of its own elements no longer stalls the compiler). Without it eight stores like `h[:a1] ||= h[:a0]` take over 30 seconds to compile under the flag, where they take 0.01 today.
