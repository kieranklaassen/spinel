<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`$? == $?` is false under `SPINEL_GC_STRESS=2`. The cure costs a comparison of two reads of `$?` 11 instructions with gcc and 16 with clang, whether or not a child has run; a comparison whose first operand is not a read of `$?` compiles to the same C.

```ruby
system("exit 3")
p $? == $?     # master at SPINEL_GC_STRESS=2: false. CRuby: true
```

Each read of `$?` builds its Process::Status (`sp_last_process_status` allocates). The `==` and `!=` templates of two statuses (`src/builtin_ops.c`) bind the first to a C temporary and then evaluate the second: that allocation collected the first, and its status word was read from freed memory. The two rows now go through `emit_op_pstatus_cmp` (`src/codegen_ops.c`). Where the second operand is a read of `$?` and the first operand's value is one too (the read, or a begin, `&&` or `||` whose value arm is one), the row's template is emitted with its receiver rooted; every other pair gets the template as it stands.

Cost, by callgrind on master 8dc55225, 1,000,000 comparisons: `$? == $?` takes 157,801,411 instructions before and 168,593,352 after with gcc, 158,067,689 and 173,859,458 with clang. `a == b` on two locals, `a == $?`, `h.st == $?` through a reader, `$? != a` and `$? == 768` compile to the same C as before. `tools/cident.sh` against that master: 6,445 identical, 1 differ, 0 refusal changes, of 6,446: `test/process_status_equality.rb`.

`test/process_status_equality.rb` fails under stress on master for this cause; it gains the `&&`, `||` and begin forms and joins `GC_STRESS_TESTS`.

Not here: a first operand whose read of `$?` is a conditional's arm or a case's arm. `(true ? $? : nil) == $?` and `(case 1 when 1 then $? end) == $?` are false under `SPINEL_GC_STRESS=2` as on master. Taking those arms would make `(a.nil? ? a : $?) == $?`, which is right on master, pay the root.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
