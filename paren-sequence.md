<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`x = (1; [])` assigned nil, and so did `w = (3; {})`, `def r = (1; [])`, `p((4; []))`, `[(5; [])]` and `(7; Array.new)`, where CRuby answers the empty collection each time. `(1; []).size` raised NoMethodError, and `x = (1; []); x << "a"` did not build, an `sp_IntArray` assigned to an `sp_StrArray`. Of 86 programs with the sequence in a different position each (a local, an instance variable, a global, a constant, a method's body, a block's value, a receiver, an argument, a default, an element, an arm, nested), 17 answered as CRuby does on 0d370b71, 48 answered differently and 21 stopped in the C compiler. All 86 answer as CRuby does now, under `SPINEL_GC_STRESS=1` too.

```ruby
x = (1; [])
p x                    # nil, CRuby []
def h = (1; {})
p h.size               # nil, CRuby 0
p [(5; []), (6; {})]   # [nil, nil], CRuby [[], {}]
p((1; []).size)        # NoMethodError, CRuby 0
```

The empty literal carries no element type, so it infers to UNKNOWN until its use settles one, and the slot that takes `[]` or `([])` reads the literal to do that. Nothing reads through a sequence of several statements: the slot stayed untyped and took the boxed form, and a value of no type boxes to nil. `infer_uncached` now types such a sequence poly, the answer a `begin` whose body ends in the literal already has (#3496), and `emit_expr_node` builds the literal boxed there. Both arms go through helpers (`an_paren_ty`, `emit_paren_tail`), so neither function grows: `infer_uncached` is six lines shorter and `emit_expr_node` one.

A sequence of one statement, and one ending in anything else, are typed and emitted as before. The C of the 5,721 programs under `test/`, `benchmark/`, `examples/` and `packages/` is byte-identical between 0d370b71 and the same commit with this change, and so is optcarrot's (`build/optcarrot-single.c` from each compiler, compared with `cmp`).

Typing the sequence as the container the literal defaults to, as an if/else arm is, was tried and not kept: `x = (1; {}); x[:a] = 1` then raised TypeError, the StrPolyHash default meeting a Symbol key. The boxed form is the one `begin; 1; {}; end` takes today.

Two neighbours are not touched here. `x = begin; 1; ([]); end` does not build before or after (a `void` temp), and a reader written as a sequence, `def s = (nil if @c; (@s ||= +""))`, still hands `s << x` a copy: that one is a String sharing route, which CONTRIBUTING.md asks not to be widened per route.

The test is `test/paren_sequence_empty_container.rb`. Its `.expected` was written by ruby 3.3.6 with `--enable-frozen-string-literal`; it prints no non-empty Hash, so 4.0 prints the same.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
