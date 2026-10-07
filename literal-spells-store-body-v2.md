<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

An interpolated String, a Symbol or a Regexp whose text spells a store into an instance variable was rewritten by the write-barrier pass.

```ruby
class Q
  attr_accessor :w
end
q = Q.new
q.w = [1]
n = 3
puts "q->iv_w = #{n};"
p :"q->iv_w = 1;" == ("q->" + "iv_w = 1;").to_sym
p("xq->iv_w = 1;" =~ /q->iv_w = 1;/)
```

Master (3e2df1d7b) prints `SP_WBO(q)-3;`, `false` and `nil`. CRuby prints `q->iv_w = 3;`, `true` and `1`.

The pass reads the emitted C as text and wraps what reads as a store into a reference instance variable or a captured local (`(*_cell_x) =`). A frozen literal is written after the pass, but the written pieces of an interpolation, the Symbol name table and a Regexp's source are in that text. Both scans now ask, of a store they are about to wrap, whether it stands inside a string literal on its C line, and leave it if so. A store written behind such a string on the same line is wrapped as before.

`make cident` against master: no program changes its C besides the new test.

Test: `test/gc_minor_literal_spells_store.rb`, in `GC_MINOR_TESTS`, 20 lines; 11 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
