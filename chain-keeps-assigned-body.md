<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
t = +"abc"
t.insert(0, "a").concat((t = +"q"; "x"))
p t
```

```
spinel diff: output-diff
  program: rebound.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"q"
+"aabcx"
```

A regression of pull request 7778 ("A mutator on a self-returning String mutator's result reaches the variable"): before it `t` kept "q". Since it, a link after the first writes its result back to the variable the chain starts from. An argument of that link can assign the variable; the chain goes on changing the String it ran on, and the write-back then replaced the variable's new String with the chain's result. `t.upcase!.sub!((t = +"q"; "A"), "z")` leaves "zBC" and is older: a bang chain has written back that way since it first did.

The write-back is now left out where the assignment is certain. The variable is a plain String slot and every link is String's own. An argument of a link after the first is the assignment, or a parenthesized sequence with it as a statement: `t = v`, `t += x` or `t, n = v, 1`, where `v` is a String no variable names yet (a literal, an interpolation, `+"..."`, a `dup`, a `+`). Nothing else in the chain can rebind the variable (`read_rebound_by`): a later link that may rebind it writes its result back as before, so the links from the assignment on leave the write-back out together, or none does. A local, an instance, a global and a class variable are covered.

Every other chain is emitted as it was: one whose variable holds a shared String or a boxed value, and one with a link the program gives String a method under, too.

Not here: an assignment that is not certain. Under a condition (`(t = +"q" if c; "x")`), in a block, or made by a method or a proc the argument calls (`@s.insert(0, "a").concat(reset)`), it was right before pull request 7778, is wrong since, and stays as it is; so does a chain with a later link that may assign the variable. An argument that changes the variable in place (`@s.chomp!` in a method it calls) moves the variable's pointer as an assignment does, so comparing the pointer when the program runs cannot tell the two apart, and that chain's write-back is right today.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: # (the pull request "A bang on a String mutator chain answers before the chain writes back")
