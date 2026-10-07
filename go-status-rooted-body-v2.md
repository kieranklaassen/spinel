<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`$? == $?` is false under `SPINEL_GC_STRESS=2`. The cure costs that comparison 11 instructions with gcc and 16 with clang; every other comparison of two statuses compiles to the same C.

```ruby
system("exit 3")
p $? == $?     # master at SPINEL_GC_STRESS=2: false. CRuby: true
```

Each read of `$?` builds its Process::Status (`sp_last_process_status` allocates). The `==` and `!=` templates of two statuses (`src/builtin_ops.c`) bind the first to a C temporary and then evaluate the second: that allocation collected the first, and its status word was read from freed memory. The two rows now go through `emit_op_pstatus_cmp` (`src/codegen_ops.c`). Where the second operand is a read of `$?` and nothing holds the first (it is not a variable's read, and not a temporary bound ahead of the call as a call's result is), the row's template is emitted with its receiver rooted; every other pair gets the template as it stands.

Cost, by callgrind on master 759d120f, 1,000,000 comparisons: `$? == $?` takes 157,800,161 instructions before and 168,592,093 after with gcc, 158,066,914 and 173,859,674 with clang. `a == b` on two locals, `a == $?`, `$? != a` and `$? == 768` compile to the same C as before. `tools/cident.sh` against that master: 6,427 identical, 1 differ, 0 refusal changes, of 6,428: `test/process_status_equality.rb`.

`test/process_status_equality.rb` fails under stress on master for this cause and joins `GC_STRESS_TESTS`; it is the test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
