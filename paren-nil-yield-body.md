<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
def show(x)
  x
end
def passed
  show((yield))
end
p passed { 9 }
p passed { "s" }
p passed { nil }    # did not build; CRuby prints 9, "s", nil
```

Where blocks of different types make a yield's value boxed, the parentheses around it box what each call site's block answers, by that block's own type. A block answering nil was left out: its splice answers a bare 0, and the parentheses handed that on as it stood ("incompatible types when assigning to type 'sp_RbVal' from type 'int'"). They now box it as nil, as the same yield without parentheses is.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
