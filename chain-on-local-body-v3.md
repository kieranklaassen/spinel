<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
u = +"u"
u.replace("r").concat("c")
p u
```

```
spinel diff: output-diff
  program: chain.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"rc"
+"r"
```

The second link's receiver is the first link's value, a temporary, so its change went there and `u` kept the first one alone. `s.prepend("b").prepend("a")` left "bc" and `s.clear.concat("z")` left "". The `replace` chain raised FrozenError until pull request 7684 made that value a new String; since then it is silent.

`s = +""; s.reverse!.concat("x").clear; p s` is "" in CRuby and was "" here until pull request 7642 wrote a bang chain's value back; master prints "x", because the last link still changes a temporary.

A statement whose value nothing reads now runs each link on the local: `s.m(x).n(y)` becomes `(s.m(x); s.n(y))`, for the links that always answer their receiver (`<<`, `concat`, `prepend`, `clear`, `reverse!`, `freeze`, `force_encoding`, and `replace` by a literal).

Not here. Each link becomes the statement `s.m(x)`, so the rewrite is made only where that statement does today what the link did, and these chains stay as they were:

- a link the program defines a method named as (the statement runs the builtin);
- a local a lambda, a proc or a kept block reads (two such statements do not build);
- a local that may be nil when the chain runs. The nil facts are made after this pass, so it asks for every write of the name to be a String made on the spot and one of them to stand ahead of the chain; a chain on a parameter is left;
- a local written with an operator (`s += x`);
- an `insert`, an index assignment as the last call, and a `replace` by anything but a literal (the statements do not root what they take);
- a chain whose value is assigned, passed, compared or returned, and one on anything but a String local.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
