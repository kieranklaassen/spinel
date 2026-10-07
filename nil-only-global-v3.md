<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
$log = nil
p $log.to_a               # [] in CRuby, nil here
p $log.to_a.size          # 0 in CRuby, NoMethodError here
p "#{$log.to_a}"          # does not build here (a C error)
```

A global the program only ever writes nil to has no type through the fixpoint. `an_phase_reconcile_check` gives it the boxed slot afterwards and stamps its reads, but a call on such a read had been typed with a receiver of no type and had none itself: it was emitted for its effect and its value dropped, `(sp_poly_to_a_call(gv_log), sp_box_nil())`. The pull request "A global the program never assigns reads boxed from the first round" cured the global with no write at all (`p $never.to_a` prints [] on master); one written nil, by `$log = nil` or `$log ||= nil`, still answers as above.

Whether a global has a write that is not nil is a question about the program's text, so `register_globals_consts` answers it before the types are inferred and boxes the global there (`box_nil_only_globals`). The read, the call on it and what holds the call's value are then typed together: `$log.to_a + [1]` is [1], and `p($hook ? $hook.call(1) : 0)` prints 0 where master does not build it. A global with any other write, an op-assign or a multiple-assignment target is left to the fixpoint. The call plan's nil target does not reach these calls: it decides for a receiver typed as a String, an Array, a Hash or an IO, and this global has no such type.

Not in this change: `$log.to_h.merge({})` answers {} and aborts under `SPINEL_GC_STRESS=2`, as the same call on a boxed local does on master; a global whose name starts with an underscore is left as it was.

`make cident REF=upstream/master` on 7fbcf219: `6320 identical, 1 differ, 0 refusal changes`; the one that differs is the new test. `test/nil_only_global_call_value.rb` does not build on master; it passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints no non-empty Hash and no message text)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
