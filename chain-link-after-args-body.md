<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"a-"
s.insert(0, "a").concat((s << "y"; ""))
p s
```

```
spinel diff: output-diff
  program: chain.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"aa-y"
+"aa-"
```

It printed "aa-y" before pull request 7778. A link of a chain reads its receiver before its arguments run. In CRuby that receiver is the variable's String, so an argument that changes the String in place changes what the link is about to change. In a plain String slot the argument leaves the variable naming a new text, the link computes from the text it read, and the write-back put that over the change. Where the link has something to add the answer was wrong before as well: `concat((s << "y"; "z"))` gave "aa-y" then and gives "aa-z" now, for "aa-yz".

With two such arguments it is a memory fault as well: `s.insert(0, "a").sub!((s.insert(0, "ya"); "a"), (s.insert(0, "ya"); "z"))` prints "za-" for "yzyaaa-", and under `SPINEL_GC_STRESS=2` it stops with "the mark reached a freed heap string".

Such a link is now made on the variable after its arguments: the chain runs for what it does, the arguments run, and the mutator is then the variable's own call. A chain that answered nil raises NoMethodError after the arguments, as in CRuby.

Only where that is certain: the variable is a plain String slot, every link is String's own, an argument of the link calls a String mutator on the variable, and nothing from the first link on can assign it. Every other chain keeps its C.

Not here, each left as it was:

- a shared String, as `x = s.insert(0, "a").concat((s << "y"; ""))` makes `s`: the same loss stands there;
- a link called by `&.`, and a chain one of whose arguments may assign the variable;
- the variable's own call, `s.prepend((s << "y"; "z"))`, which is no chain and lost the "y" before pull request 7778 too.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: # (the pull request "A String mutator chain keeps a variable its argument assigned")
