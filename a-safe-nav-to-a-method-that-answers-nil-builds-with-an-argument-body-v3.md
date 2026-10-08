<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Logger
  def info(msg) = puts("info: #{msg}")
end
log = ARGV.size > 5 ? nil : Logger.new
verbose = ARGV.size == 0
verbose && log&.info("started")
```

```
spinel diff: link-error
  program: w1.rb
  ruby:    exit 0
  spinel:  the C did not build

w1.rb: In function '_sp_main_body':
w1.rb:6: error: variable or field '_snr9' declared void
w1.rb:6: error: void value not ignored as it ought to be
```

with gcc; clang says `variable has incomplete type 'void'`. It is any method whose C function is `void` (a body that ends in `puts`, in `nil` or in a bare `return`), called with an argument through `&.` on a receiver with a C nil of its own, where the call cannot stay in its place in the statement, among them: under `&&`, `||`, `and` or `or`, as the test or an arm of a ternary whose value is read, as the value of `||=`, a `case`'s subject, the value of a rescue modifier, or before a later operand that is made (`[log&.info("a"), t + "b"]`).

Depends on "A `&.` call whose value hoists builds, and runs in its place": that change keeps a guard in the call's place wherever nothing later in the statement needs it ahead, and this one takes only what it leaves. Without it this guard would take those calls too, and run them ahead of what stands before them: the test's last line, `puts "#{tick} <#{log&.info(t + "p")}>"`, would print `info: xp` before `tick`.

Each argument of such a call runs into a temp ahead of it. Where the value arm of a `&.` hoists statements like these and the call cannot stay in place, `emit_call_safe_nav_arms` makes the guard an `if` ahead of the statement and keeps the call's value in a `_snr` temp declared in the call's C type; for a call with no value that is `void _snr9 = 0;`. Such a guard is now the `if` alone, the hoisted statements and the call inside it, and what reads the call reads `((void)0)`: a void expression, as the unhoisted guard `(nil ? 0 : (call))` already is.

Cost: none. A guard whose call has a value is emitted as it was: the corpus's generated C is unchanged.

Not in this change. Where the statement runs something before the call and makes something after it, or the call is a ternary's test in an interpolation or under `+`, the guard ahead runs first: with `def tick(x) = (puts "tick #{x}"; x)`, `puts "#{tick(1)} <#{log&.info(t + "a")}> #{tick(2)}"` and `puts "#{tick(1)} #{log&.info(t + "a") ? 1 : 2}"` print `info: xa` before `tick 1`, as the same lines do on master for a method that answers a value. Given as the first argument of a program's method, the call runs after a later argument: with `def side = (puts "side"; "s")`, `p two(log&.info(t + "a"), side)` prints `side` before `info: xa`, as the same statement with `.` for `&.` does on master. And a call read through `!` or a further `&.` builds on master and never runs: `p !log&.info("m")` prints `true` and `p log&.info("l")&.to_s` prints `nil`, with no `info:` line, on master and here.

`test/safe_nav_void_call_arg_temp.rb` prints 26 lines; master does not build the file.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
