<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`$? == $?` is false under `SPINEL_GC_STRESS=2`. 1,000,000 plain comparisons were right.

```ruby
system("exit 3")
p $? == $?     # master at SPINEL_GC_STRESS=2: false. CRuby: true
```

Each read of `$?` builds its Process::Status (`sp_last_process_status` allocates). The `==` and `!=` templates of two statuses (`src/builtin_ops.c`) bound the first to a C temporary and then evaluated the second: that allocation collected the first, and its status word was read from freed memory. The two templates now root the first before the second is made.

Cost, by callgrind on master 4f8b737c: 1,000,000 `$? == $?` take 157,800,626 instructions before and 168,592,558 after, 11 a comparison. `tools/cident.sh` against that master: 6,405 identical, 1 differ, 0 refusal changes, of 6,406: `test/process_status_equality.rb`.

`test/process_status_equality.rb` fails under stress on master for this cause and joins `GC_STRESS_TESTS`; it is the test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
