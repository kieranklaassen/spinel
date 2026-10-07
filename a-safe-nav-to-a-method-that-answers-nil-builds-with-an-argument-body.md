<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Logger
  def info(msg) = puts("info: #{msg}")
end
log = ARGV.size > 5 ? nil : Logger.new
log&.info("started")
```

```
spinel diff: link-error
  program: w1.rb
  ruby:    exit 0
  spinel:  the C did not build

w1.rb: In function '_sp_main_body':
w1.rb:5: error: variable or field '_snr9' declared void
w1.rb:5: error: void value not ignored as it ought to be
```

with gcc; clang says `variable has incomplete type 'void'`. It is any method whose C function is `void` (a body that ends in `puts`, or in `nil`), called with an argument through `&.` on a local, a parameter or an instance variable that holds an object or nil. `log&.info(1)` fails the same way; only a call with no argument built, because its guard stayed an expression.

Each argument of such a call runs into a temp ahead of it. Where the value arm of a `&.` hoists statements like these, `emit_call_safe_nav_arms` makes the guard an `if` and keeps the call's value in a `_snr` temp declared in the call's C type; for a call with no value that is `void _snr9 = 0;`. Such a guard is now the statement alone, the hoisted statements and the call inside the `if`, and what reads the call reads `((void)0)`: a void expression, as the unhoisted guard `(nil ? 0 : (call))` already is.

Cost: none. A guard whose call has a value is emitted as it was: the corpus's generated C is unchanged.

`test/safe_nav_void_call_arg_temp.rb` prints 15 lines; master does not build the file.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
