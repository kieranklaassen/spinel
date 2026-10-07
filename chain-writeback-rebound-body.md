<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
t = +"abc"
t.insert(0, "a").concat((t = +"q"; "x"))
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
-"q"
+"aabcx"
```

A regression of pull request 7778, and one older fault cured by the same line.

Since that pull request the chain a value-form mutator writes its result back through passes `insert`, `prepend`, `concat`, `replace` and `<<`. The write-back is to the variable by name, so an argument that gave the variable another String lost it to the chain's result. Before, the chain ended at the `insert` and `t` kept "q". The same happens through a proc that assigns `t`, and on a global or an instance variable through a method that assigns it. `t.upcase!.sub!((t = +"q"; "A"), "z")` leaves "zBC" and is older: a bang chain has written back that way since it first did.

Where a call of the chain can rebind the variable (`read_rebound_by`, asked of each call's arguments and block), the result is now written back only while the variable still names the String the chain ran on, the mutator's receiver: `if (lv_t == _t2) lv_t = _t1;`. A chain none of whose calls can rebind its variable is emitted as it was.

Not here:

- a chain with a link the program gives String a method under. `def prepend(*a) = +"other"` makes `s.prepend("x").concat("z")` leave "otherz" (CRuby "abc"), also since pull request 7778. Such a method may change its receiver and answer it, another pointer here, so the test would break `def prepend(x); self << x; self; end`, which is right today. The write-back stays as it is there;
- a variable that holds a shared String or a boxed value: its write-back goes through the handle or the box, not a pointer.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A bang on a String mutator chain answers before the chain writes back")
