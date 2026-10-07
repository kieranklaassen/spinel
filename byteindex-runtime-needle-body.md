<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
g = { "k" => "ab", "n" => 1 }
p "cab".byteindex(g["k"])
```

prints `nil` (`spinel diff`: output-diff). CRuby prints `1`. In other places the same call compares false (`== 1`), raises NoMethodError (`.nil?`: undefined method 'nil?' for unknown), is refused (as a condition) or does not build (before `||`).

The emitter searched for a boxed needle, but the call was typed for a String or a Regexp needle alone. With a boxed one it had no type, so the search ran and its answer was dropped. Now the call is typed Integer-or-nil for a boxed needle too, and its arm picks the search by the needle's tag, as the arm for `index` and `rindex` does. A boxed Regexp searches (it raised TypeError: no implicit conversion of Regexp into String), a String or an appended String is searched for, and anything else is the conversion's TypeError as before.

Cost: the answer is now kept and the receiver and the needle are rooted across the search, as `index` roots them (callgrind on 70cddab37194, gcc, 100,000 calls: `"cab".byteindex(g["k"])` goes from 163 to 181 instructions a call). A needle with a static type emits the C it did. No corpus program's C changes (`make cident`: 6,355 identical; the new test is refused on master), optcarrot's included.

Not changed: an offset that falls inside a character raises IndexError in CRuby. Here the search runs from it, as it does on master with a literal for the needle (`"héabab".byteindex("ab", 2)` answers 3, `byteindex(/b/, 2)` answers 4). So a boxed Regexp with such an offset, which stopped at the TypeError, now answers what the Regexp literal answers.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
