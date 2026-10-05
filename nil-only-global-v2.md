<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
$log = nil
p $log.to_a               # [] in CRuby, nil here
p $log.to_a.size          # 0 in CRuby, NoMethodError here
p "#{$log.to_a}"          # does not build here (a C error)
```

A global that only ever holds nil, or is never assigned, has no type through the fixpoint. `an_phase_reconcile_check` gives it the boxed slot afterwards and stamps its reads, but a call on such a read had been typed with a receiver of no type and had none itself. It was emitted for its effect and its value dropped: `(sp_poly_to_a_call(gv_log), sp_box_nil())`. `to_h`, `&`, `|` and `^` answered nil the same way.

Whether a global has a write that is not nil is a question about the program's text, so `register_globals_consts` answers it before the types are inferred and boxes the global there (`box_nil_only_globals`, 23 lines; the diff adds 30). The read, the call on it, the call on that and the conditional around it are then typed together: `$log.to_a + [1]` is [1], `def f = $log.to_a` answers [], and a guarded call that never runs has a value: `p($hook ? $hook.call(1) : 0)` prints 0 where master does not build it (a C type error). The statement forms, `$hook.call(1) if $hook` and an `if` with an `else`, build and answer as they did. A global with any other write, an op-assign or a multiple-assignment target is left to the fixpoint as before.

Measured on 1,280 generated programs (the global written nil once, twice, in a method, by `||=`, never; 19 of nil's own methods, 29 calls on the answer and 19 guarded calls, as an argument, a condition, an element, an interpolation, a local's value, a method's value, in a block; typed globals as controls), master c6bbdfbc9 against this commit, gcc, plain and under `SPINEL_GC_STRESS=1` and `2`, CRuby 3.3.6 as the reference: 744 right on master and 1,178 here. Every program right on master is right here, and none that raised or did not build answers wrongly.

Not covered: `$log.to_h.merge({})` answers {} and aborts under `SPINEL_GC_STRESS=2` ("the mark reached a freed slot"), as the same call on a boxed local does on master (`x = nil; x = 5 if ARGV.size > 5; p(x.to_h.merge({}))`); twelve of the 1,280. A global that holds nil and is later given a value is typed by that value, as before. A name that starts with an underscore is left as it was (`$_tmp = nil; p $_tmp.to_a` prints nil): only a name that starts with a letter is boxed, so that `$_` and the other globals Ruby sets itself are not touched.

`make cident REF=upstream/master` on 5c2dea51: `6078 identical, 1 differ, 0 refusal changes`. The one that differs is the new test. `tools/refusals.sh`, `reject-test` and `make nil-check-test` pass. optcarrot's generated C is byte-identical.

`test/nil_only_global_call_value.rb` does not build on master. It passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints no non-empty Hash and no message text)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
