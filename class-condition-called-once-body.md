<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class K; end
def one
  puts "one"
  K
end
puts "t" if one
```

printed `one` twice; CRuby prints it once. `sp_class_nil_p` was a macro that read its operand twice, and three places hand it the call itself: a condition over a class value (`if`, `unless`, `?:`, `elsif`, `until`), `!`, and `respond_to?`. Each ran the method twice when it answers a class or a module. It is a `static inline` function now.

Its other callers (`&&`, `||`, `||=`, boxing a class) already hand it a temporary or a variable. The compiler is untouched, so every generated C file is as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
