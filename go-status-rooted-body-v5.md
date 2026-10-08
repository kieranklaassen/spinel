<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`$? == $?` is false under `SPINEL_GC_STRESS=2`. The cure costs a comparison whose first operand's value is a read of `$?` 11 instructions with gcc and 16 with clang, whether or not a child has run: `$? == $?`, `(a && $?) == $?`, `($? || a) == $?`, each false under stress on master. Every other comparison compiles to the same C.

```ruby
system("exit 3")
p $? == $?     # master at SPINEL_GC_STRESS=2: false. CRuby: true
```

Each read of `$?` builds its Process::Status (`sp_last_process_status` allocates). The `==` and `!=` templates of two statuses (`src/builtin_ops.c`) bind the first to a C temporary and then evaluate the second: that allocation collected the first, and its status word was read from freed memory. The two rows now go through `emit_op_pstatus_cmp` (`src/codegen_ops.c`). Where the second operand is a read of `$?` and the first operand's value is one too (the read, or a begin or `&&` whose value is one, or `||` whose left arm is one), the row's template is emitted with its receiver rooted; every other pair gets the template as it stands.

Cost, by callgrind on master 42557a3c, 1,000,000 comparisons, before and after: `$? == $?` takes 157,801,910 and 168,593,352 instructions with gcc, 158,068,198 and 173,859,949 with clang; `(a && $?) == $?` takes 160,617,758 and 171,618,749 with gcc, 161,886,082 and 177,886,108 with clang. `a == b` on two locals, `a == $?`, `(a || $?) == $?`, `h.st == $?` through a reader, `$? != a` and `$? == 768` compile to the same C as before. `tools/cident.sh` against that master: 6,468 identical, 1 differ, 0 refusal changes, of 6,469: `test/process_status_equality.rb`.

`test/process_status_equality.rb` fails under stress on master for this cause; it gains the `&&`, `||` and begin forms and joins `GC_STRESS_TESTS`.

Not here, each false under `SPINEL_GC_STRESS=2` as on master:

- `(a || $?) == $?` where `a` is nil. Its value is `a`'s wherever `a` holds a status, and that one is held, so the comparison keeps its C; taking the right arm would make it pay the root where it is right.
- `($? || nil) == $?` and `(nil || $?) == $?`. A nil literal beside the read makes the comparison `sp_poly_eq`, another emitter with the same hole.
- A first operand whose read of `$?` is a conditional's arm or a case's arm: `(true ? $? : nil) == $?` and `(case 1 when 1 then $? end) == $?`. Taking those arms would make `(a.nil? ? a : $?) == $?`, which is right on master, pay the root.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
