<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`!=` between a value typed as the program's exception class and a rescued
exception is refused at compile time, where `==` compiles.

```ruby
class MyErr < StandardError; end
begin
  raise MyErr, "a"
rescue MyErr => e
  p(e != e)
end
# Spinel: unsupported equality: node 17 (CallNode `!=`) ...
# CRuby:  false
```

The receiver there is typed as the class and the argument as a rescued
exception (the same variable, read without the narrowing). `k != e` with
`k = MyErr.new("n")` and a `rescue => e` is refused the same way. For that
pair of types `emit_call_exception_arms` has an arm for `==` and `eql?`
(`sp_exc_eq`, class and message) and none for `!=`, which fell through every
equality arm to the refusal. `!=` takes the same arm now, turned round, so
it is `!(a == b)` as in CRuby, unless the class defines `==` itself.

It answers what `!(a == b)` answers on master, line for line: the C is that
expression's, less a pair of parentheses. `sp_exc_eq` compares class and
message and has no backtrace to compare (docs/limitations.md), so for two
different exceptions of one class and one message `==` says equal where
CRuby does not, and `!=` says the opposite of it, as it must.

Test: `test/exception_class_ne_rescued.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
