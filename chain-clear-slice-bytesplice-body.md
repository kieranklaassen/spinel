<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
t = +"abc"
t.clear.concat("z")
p t
```

```
spinel diff: output-diff
  program: chain.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"z"
+""
```

What pull request 7778 left. It took the chain a value-form mutator writes its result back through past `insert`, `prepend`, `concat`, `replace` and `<<`. Two things still change a copy:

- `clear`, `force_encoding`, `bytesplice` and `append_as_bytes` answer their receiver as those five do, and the chain ended at them: `s.bytesplice(0, 1, "Z") << "x"` lost the "x". The chain passes them now.
- `clear`, `slice!` and `bytesplice` as the last call: `t.concat("x").clear` left "abcx". On a chain from a String variable the chain now runs once and the call is then made on the variable. `slice!` and `bytesplice` ran such a receiver two to four times (`t.concat("1").bytesplice(0, 2, "Q")` left "abcdef11"); it runs once.

The `append_as_bytes` lines are in a test of their own: the method is CRuby 3.4 and later, so that test's `.expected` is to be run with Ruby 4.0 at the gate.

Not here, each left as it was:

- a chain with a link the program gives String a method under, or a last call under such a name;
- a last `clear`, `slice!` or `bytesplice` where a call of the chain can rebind the variable. Through one of the four links the write-back is tested when the program runs, as it is through the other five; on a shared String or a boxed value, where it cannot be, the chain ends at that link;
- a local read as a String out of a boxed slot (`if x.is_a?(String)`). Through `insert`, `prepend`, `concat`, `replace` or `<<` such a chain does not build today ("lvalue required as left operand of assignment"); before pull request 7778 it built and was silently wrong.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A String mutator chain writes back only to the String it ran on")
