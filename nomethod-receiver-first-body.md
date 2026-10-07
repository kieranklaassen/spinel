<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def recv = (puts "recv"; ARGV.size > 5 ? "s" : 5)
def tick(n) = (puts "tick #{n}"; n)
begin
  recv.zork(tick(1), tick(2))    # gcc: "tick 1", "tick 2", then "recv"
rescue NoMethodError
  puts "no zork"
end
```

A call that no method answers ran its arguments before its receiver when built with gcc. `emit_unresolved_call` hands both to the error in one C call, `sp_nomethod_msg_args("zork", <receiver>, n, (sp_RbVal[]){<arguments>})`, and C leaves the order of a call's arguments open. Nothing held one of them either while the next was made: `r.zork("a" + x, "b" + x)` aborts with `SPINEL_GC_STRESS=2` ("the mark reached a freed heap string"), the first String freed while the second is built. With `SPINEL_GC_STRESS=1` nothing aborts and the answer is wrong: in the new test `e.args` of `5.zork("a" + x, mk(x), "c" + x)` reads `["abc", [...], "cbc"]` for `["abc", ["bc", 1], "cbc"]`.

Where a receiver and an argument both run, or two arguments are temporaries and one is a heap value, the receiver and then each argument is bound to a rooted temporary first (`emit_rooted_arg_list`, as the boxed key-list builtins bind theirs).

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,4 +1,4 @@
-recv
 tick 1
 tick 2
+recv
 no zork
```

Every other call compiles to the C it did: of the 6,420 programs of the corpus the generated C of one changes, the new test (`tools/cident.sh`), and a call that is answered costs what it did (callgrind, 200,000 dispatched calls of `b.val("a" + x)`: 108.47M before and after). A call that raises pays 6 to 31 instructions more, of about 5,900. Test: `test/nomethod_runs_receiver_first.rb`, also one of `GC_STRESS_TESTS`.

Not here: a call with one temporary (`pick(c, x).zork(1)`, `5.zork("a" + x)`) still loses it at `SPINEL_GC_STRESS=2`, inside the helper that lists the arguments. That is "A NoMethodError holds its receiver and arguments before it lists them". And `NoMethodError#receiver` of a String that is a temporary (`("q" + x).zork(1)`) is nil where CRuby answers the String, as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # ("A call no method answers runs its arguments before it raises")
