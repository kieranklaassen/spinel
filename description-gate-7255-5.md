# PR 7255: the gate block for af34c8c3 on master adc715c6 (green)

The Mac ran the full gate on af34c8c3 merged with master adc715c6 from 05:46 to 06:06 UTC on 2026-10-03: ALL GREEN. adc715c6 is matz's own fix of the two FFI tests ("The FFI nil tests take fabs from the running process, not libm.so.6"). The head af34c8c3 is unchanged.

Each Old below is the live text as the Mac reported its own edit of 05:22 UTC, relayed by the coordinator; this thread cannot read the description. Each Old is to occur exactly once in the live text; if one does not, stop and say so.

## 1. The fence

Old, the content of the fence:

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
Tests:     5610 pass,        2 fail,        0 error
```

New, the content of the fence, the lines as the gate on adc715c6 printed them:

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
Tests:     5612 pass,        0 fail,        0 error
gate: ALL GREEN
```

## 2. The paragraph under the fence: removed

Old:

```
No `gate:` line: the gate stops at two failing tests, `pkg.ffi.ffi_nil_numeric_arg` and `pkg.fiddle.fiddle_nil_numeric_arg`. Both are master's own: 5fbf7aca added them, they open `libm.so.6`, which macOS does not have, and they fail the same way on plain master 62b01c7f on the same machine; on Linux both pass on plain master 62b01c7f. This branch changes nothing under `packages/`. Every other leg passed.
```

New: nothing. The paragraph goes together with one of the two blank lines around it, so that the fence's closing line, exactly one blank line, and the "Run on macOS (arm64)" line follow one another.

## 3. The run line

Inside the line that begins "Run on macOS (arm64)" only:

Old:

```
at 62b01c7f plus this branch.
```

New:

```
at adc715c6 plus this branch.
```

The rest of that line stays as it is.

## 4. The optcarrot checkbox

Old:

```
byte-identical to master's at 62b01c7f)
```

New:

```
byte-identical to master's at adc715c6)
```

By the Mac's run optcarrot's checksum is 59662 and its C is byte for byte master adc715c6's.

## 5. The cident paragraph: no change

"`reject-test` and the gate's property checks pass here, on the branch and merged with 62b01c7f (scale-test 1.74 / 4.82 / 6.29 / 4.24, master's four)" stays at 62b01c7f. That sentence is this thread's own run, not the Mac's: `make gate-props` on af34c8c3 merged with 62b01c7f, and `make scale-test` on plain 62b01c7f for "master's four". Neither was rerun on adc715c6, so the sha stays the one those runs used.

After 3 and 4 the description still names 62b01c7f once, in that sentence, and names adc715c6 twice.

## pr2-body.md

Its fence now holds the six New lines of 1, and its optcarrot box reads "(it did not change: byte-identical to master's at adc715c6)". It never held the paragraph of 2. It does not hold the "Run on macOS (arm64)" line: the Mac wrote that line and this thread knows only its beginning, so it is not copied in. Apart from that line the file is the live text after 1 to 4, as far as the live text is known here.

## What rests on what

The six lines, "ALL GREEN", the optcarrot result and that both FFI tests now pass on macOS: the Mac's run, relayed by the coordinator. Checked here by git: adc715c6 is on upstream master, its subject is as quoted, and it changes only packages/ffi/test/ffi_nil_numeric_arg.rb and packages/fiddle/test/fiddle_nil_numeric_arg.rb. No run on adc715c6 was made in this thread.
