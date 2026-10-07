<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A call written as a `when` value never ran when its type cannot match the subject's.

```ruby
$n = 0
def name; $n += 1; "s"; end
case 5
when name then puts "m"
else puts "e"
end
puts "n=#{$n}"
```

Master (5390d300) prints `e` and `n=0`. CRuby prints `e` and `n=1`.

`emit_when_typed_test` folds a value whose type can never equal the subject's (a String beside an Integer, a Symbol beside a String) to a constant 0 and does not emit the value. The arm still answers 0, now after the value where the value has a side effect: `((void)(name()), 0)`. A literal or a plain local keeps the bare 0, so the C of a program without such a call is unchanged.

Test: `test/case_when_value_call_runs.rb`, 23 lines; 16 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
