<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def tick(n) = (puts "tick #{n}"; n)
def arr(n) = (puts "arr #{n}"; [n, 1])
xs = [1, 2]
p arr(8) + xs.map { |i| tick(i) }
```

printed `tick 1`, `tick 2`, `arr 8`, `[8, 1, 1, 2]`: the block of the second operand ran before the first operand. CRuby runs `arr(8)` first. The same with `-`, `|`, `concat`, `zip`, `==`, `fetch`, `puts` and a program's own methods, wherever an operand written before the block's call runs code.

It costs a right program 3 to 8 instructions a call (callgrind, 200,000 calls of `arr(i) + xs.map { |x| inc(x) + i }`: 237,777,769 to 238,556,835) where an operand runs code and a later one runs a block that calls something; a block of reads and arithmetic alone is emitted as before, and so is every call whose earlier operands run nothing.

A call like `xs.map { ... }` is written as a loop ahead of the statement that uses its value. Three places keep such statements behind the operands written before them, and each missed a case:

- `emit_operands_in_order` holds what an operand hoists in its place when that runs code of its own (`operand_hoists_effect`). The test looked at the operand call's receiver and arguments and not at its block; it asks the block too.
- A call on a receiver that is one of several classes holds an argument's hoisted statements in place once something has run (`emit_poly_arg_temp`). A splatted argument was written without that: `r.rest(tick(8), *xs.map { |i| tick(i) })` ran the map first, and so did an argument after a splat that runs code. `emit_poly_splat_temp` holds the splat's the same way.
- The Array a rest parameter receives is built inside the call's expression (`emit_rest_pack_kwh`) while what its elements hoist went ahead of the statement: `k.rest(tick(8), *xs.map { |i| tick(i) })` on a receiver of one class. An element after one that has run code holds what it hoists in its place.

Left as before, each still running the block first: a Hash literal's key before such a value (`{ tick(8) => xs.map { ... } }`), the parts of an interpolation, `[tick(8), xs.map { ... }.size].max`, `arr(8).push(*xs.map { ... })`, `arr(8).values_at(*xs.map { ... })`, and `+` over two Arrays of different element kinds. A block whose body can raise without calling anything (`xs.map { |x| 10 / x }`) is still taken for one that runs nothing.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
