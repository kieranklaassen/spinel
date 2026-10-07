<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
$n = 0
nil&.then { $n += 10 }
p $n
def t; nil&.tap { $n += 10 }; end
```

printed 10 where CRuby prints 0, and the method did not build (`variable or field '_t1' declared void`). `&.` on a receiver that is nil alone ran the block of tap, then and yield_self: their emitters carry a nil receiver boxed, for `nil.tap { }`, and never look at the operator.

`sn_nil_tap_then` names the call, `sn_guard_pending` stands the emitters down for it, and the nil arm of `emit_call_safe_nav_arms` answers nil. It is a safe-navigation guard test (the call's operator, name and block, and the receiver's static type); it adds to none of the nil helpers the nil analysis retires. A receiver that is more than a read (`none&.tap { }`) was evaluated by those emitters and still is, once: by that arm, or by `emit_iteration_stmt` where the call is a statement.

Not here: a receiver that is itself a `&.` call no guard takes is left as it was. In `none&.size&.tap { }` the receiver of `size` is dropped when it is nil alone, which is another fault; with it the statement form would build and print that fault's line, so it keeps not building.

Measured on 21,924 generated programs (29 receiver forms; tap, then and yield_self, alone and in a chain; seven block forms; as a statement, a value, a condition, an argument): the C of 4,620 changes. 2,597 that printed something else and 371 that did not build are right; 1,078 were right and are; 210 still do not build (the receiver `(none rescue nil)`); 364 print the line they printed, that other fault's (`none&.tap { }&.each { }`: the `&.each` drops its receiver). None that was right is lost, and none that did not build prints a wrong line. The 4,046 right ones agree with CRuby with gcc and clang at `SPINEL_GC_STRESS` unset, 1 and 2. `make cident`: the corpus C is unchanged but for the new test, which did not build.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`test/safe_nav_nil_tap_then.rb` is written from CRuby 3.3.6; its 4.0 run is owed)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
