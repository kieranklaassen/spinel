# PR 7255: the gate block for af34c8c3

For the section ``## `make gate` (on this branch merged with current master)`` of the description. The Mac's full gate ran about 04:50 UTC on 2026-10-03 on af34c8c3 merged with master 62b01c7f.

This thread has never seen the live block: the Mac wrote it from its own run. The Old text below is the block as the coordinator described it, so the Mac matches it against what is live and says if it differs. Two of its lines are known here only by that description (the "Run on macOS (arm64) at ..." line and the optcarrot checkbox), so for those the change is given as a rule, not as a string.

## 1. The fenced block

Old, the content of the fence (the lines of the gate on 75c390c2):

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
Tests:     5602 pass,        0 fail,        0 error
gate: ALL GREEN
```

New, the content of the fence, the lines as the gate printed them, in the order the live block has them:

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
Tests:     5610 pass,        2 fail,        0 error
```

There is no `gate:` line to paste: the gate did not print one.

## 2. A paragraph added right under the fence, before the "Run on macOS" line

New:

```
No `gate:` line: the gate stops at two failing tests, `pkg.ffi.ffi_nil_numeric_arg` and `pkg.fiddle.fiddle_nil_numeric_arg`. Both are master's own: 5fbf7aca added them, they open `libm.so.6`, which macOS does not have, and they fail the same way on plain master 62b01c7f on the same machine; on Linux both pass on plain master 62b01c7f. This branch changes nothing under `packages/`. Every other leg passed.
```

## 3. The "Run on macOS (arm64) at ..." line

Keep its form. Where it names the head, af34c8c3 for 75c390c2; where it names the master, 62b01c7f for 6535952f; the time of this run for the old one. Anything else in the line that came from the old run (a result such as green or passed, a duration, a count, a line count) becomes what this run gave, or is dropped; nothing in it may say the gate was green.

## 4. The optcarrot checkbox

Keep its form, 62b01c7f for 6535952f. By the Mac's run optcarrot's C is byte for byte master 62b01c7f's, checksum 59662, so the box says the same thing about the new master. Anything else in the line that came from the old run (a result such as green or passed, a duration, a count, a line count) becomes what this run gave, or is dropped; nothing in it may say the gate was green.

## What each sentence rests on

- The five lines, the missing `gate:` line, "every other leg passed" (benchmarks 64 pass, optcarrot's C identical to master's, ruby/spec all expected-PASS), and "fail the same way on plain master 62b01c7f on the same machine": the Mac's run, relayed by the coordinator. Not run here.
- "on Linux both pass on plain master 62b01c7f": run here alone, `make build/test-results/pkg.ffi.ffi_nil_numeric_arg.ok build/test-results/pkg.fiddle.fiddle_nil_numeric_arg.ok` in a build of 62b01c7f, both PASS.
- "5fbf7aca added them": `git log upstream/master -- packages/ffi/test/ffi_nil_numeric_arg.rb packages/fiddle/test/fiddle_nil_numeric_arg.rb` names that one commit, "nil as an FFI integer or double raises TypeError, as the ffi gem does".
- "they open `libm.so.6`": packages/ffi/test/ffi_nil_numeric_arg.rb line 14, `ffi_lib "libm.so.6"`; packages/fiddle/test/fiddle_nil_numeric_arg.rb line 13, `Fiddle.dlopen("libm.so.6")`.
- "This branch changes nothing under `packages/`": `git diff --name-only ba6317b6 af34c8c3` lists the Makefile, four files under src/ and files under test/ only.

## CONTRIBUTING.md and the template, read from master 62b01c7f

CONTRIBUTING asks to run `make gate` on the branch merged with current master and paste its summary, `grep -E 'Tests:|scale-test|gate:' gate.log`, and says a pull request is merged only after the same gate passes on their side. The template's fence says "paste the Tests:, scale-test and gate: lines here". Neither says what to paste when the gate is not green.

What this block cannot honestly give: a `gate:` line. On this master the gate cannot print one on macOS, with or without this branch. The block gives the lines the run printed and says why the last one is missing; it does not claim a green gate. A green gate on 62b01c7f needs a machine that has `libm.so.6`.

The full gate on Linux, in this thread's sandbox, on af34c8c3 merged with 62b01c7f, was started about 04:53 UTC and takes about an hour; its lines go to the coordinator when it ends and are not in this file. By the earlier runs here two other tests fail in this sandbox on untouched master too (`pkg.tmpdir.tmpdir_expand_usable`, the container runs as root; `socket_ipv6_and_class_methods`, no UDP sockets), so it will not print a `gate:` line either.
