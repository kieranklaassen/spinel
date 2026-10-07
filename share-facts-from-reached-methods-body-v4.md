<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Under `--share-strings` only (the default build's C is unchanged, by "sh_targets_in reads cplan_targets; the scope-name index goes" and by this):

```ruby
a = ["a", "b"]
a.each.with_index { |s, i| p [s, i] }
a.map.with_index { |s, i| p s + i.to_s }
a.each.each_with_index { |s, i| p [s, i] }
```

does not build since that change (`error: assignment to 'sp_String *' from incompatible pointer type 'const char *'`). Of the 6,476 programs of `test/`, `test/share` and `test/reject` compiled under the flag, the C or the refusal of 187 changes, and each was run on master and here: 18 are right that on master do not build (3), die with a segmentation fault (1), are refused (9) or print something else (5); the other 169 print what they print on master; none is lost. That is more than that change took: with its answer for a receiver with no type put back, 14 of the 18 are right and 3 are not (`test/issue_3342_threads_with_native_packages.rb`, `test/literal_string_markers.rb`, `test/implicit_conversion_protocol.rb`); `test/yield_through_forwarded_block_no_append.rb` is newer than that comparison. One refusal becomes an abort the plain build already has: `test/multi_assign_operand_gc_root.rb`, refused under the flag on master, builds here and at `SPINEL_GC_STRESS=2` aborts in the collector's check, as master's plain build of it does; it is right with the stress unset and at 1. `make share-strings-test` could not show any of it: it runs `test/share`, `test/share_strings_*.rb` and the rejects of `test/share/reject.list` under the flag, and these 18 are plain tests.

The share walk read every method, also one no call reaches. Codegen emits no C for such a method and its locals are never given a type, and since that change a call on a receiver with no type is one the walk does not follow. So the `buf << x` of `__enumw_each_slice` (`builtins/enumerator.rb`, spliced with the chained iterator, called by nothing here) put an in-place change among the Strings of every call the walk does not follow, and each String that met such a call became a handle. A method of the program's own that nothing calls did the same (`def chg = @k[0] << "?"`), and so does the value of a `break` or a `next` in one, which `sh_jumps` reads.

The walk now leaves out a method no call reaches, and `sh_jumps` its `break` and `next` values. Reachability goes by name and is computed before the fixpoint and again after it, so a method that a call the walk reads reaches is read whatever its mark says: a pass writes `e.map { break }` as a call to `__enumw_map` in between, and without that 20 of the programs above lost facts about a method that is called.

Compile time under the flag, in instructions (callgrind): `test/send_name_past_1024_receiver_names.rb`, the largest test, 1,718,417,240 on master and 1,720,432,210 here; `test/bundle_misc_b.rb` 509,954,041 and 471,836,811. Without the flag the compile and the C are unchanged.

Not here: `test/bundle_classd_27.rb` is refused under the flag since that change and still is. With that change's answer put back it prints as CRuby. Its call on a receiver with no type, `receiver.data["name"]` with `receiver` one of two sibling classes, is in the main program, which is reached.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`test/share/share_strings_unreached_method.rb` is written from CRuby 3.3.6; its 4.0 run is owed)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
