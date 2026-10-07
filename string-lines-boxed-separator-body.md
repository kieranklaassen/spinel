<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
g = { "sep" => ",", "n" => 1 }
"a,b\nc,d".each_line(g["sep"]) { |l| p l }
```

prints `"a,b\n"` and `"c,d"` (`spinel diff`: output-diff). CRuby prints `"a,"`, `"b\nc,"` and `"d"`. `lines(g["sep"]) { }` splits at newlines too, and without a block `lines(g["sep"])` and `each_line(g["sep"])` raise NoMethodError for a String. A String that is itself read out of a Hash of mixed values raises it for `each_line(g["sep"]) { }` as well.

The block form of `each_line` and `lines` takes its separator only when the argument is typed String; a boxed one was dropped and the receiver was split at newlines. Now a boxed separator goes to `sp_str_lines_sep_poly`, for a typed String and for a boxed one. A String splits as the typed call does, one the program appends to as well. nil is no separator: the one line is the receiver. Anything else takes the strict conversion and raises CRuby's TypeError. A typed separator emits what it did.

No corpus program's C changes but the new test's (`make cident` against e527d205d274), and optcarrot's C is unchanged. Of 1,080 programs (nine receivers, twelve separators, ten forms) 324 that were wrong are right, the 510 that were right answer as they did, and none is lost.

Not changed: the Enumerator of a blockless `each_line(g["sep"])` answers its count to `size` (CRuby nil) and its `inspect` does not show the separator, as with a typed separator on master; and it reads its separator when it is made, so one that is no String raises there, where CRuby raises at the first line read. `each_line(g["sep"], chomp: true)` and `lines { }` with a block on a boxed receiver are as they were. Beside a class of the program that defines `each_line`, the block form on a boxed receiver stays as it was too: with a String separator that call does not build on master in value position, and a boxed separator does not join it.

Six of the probe's programs raised NoMethodError and now run into an answer master already gives. Through a boxed receiver that the program appends to, `each_line` with a block answers a String equal to the receiver, not the receiver: `x = r["s"].each_line(",") { }; p x.equal?(r["s"])` prints `false` on master, and five programs now print every line right and then that `false`. And an append to the one line a nil separator yields does not reach the receiver: `v = "a,b".dup; v.each_line(nil) { |l| l << "!" }; p v` prints `"a,b"` on master where CRuby prints `"a,b!"`, and one program now prints the same for a boxed receiver and a boxed nil.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
