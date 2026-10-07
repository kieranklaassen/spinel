<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Under `--share-strings` only (the default build's C is unchanged, by "sh_targets_in reads cplan_targets; the scope-name index goes" and by this):

```ruby
a = ["a", "b"]
a.each.with_index { |s, i| p [s, i] }
a.map.with_index { |s, i| p s + i.to_s }
a.each.each_with_index { |s, i| p [s, i] }
```

does not build since that change (`error: assignment to 'sp_String *' from incompatible pointer type 'const char *'`). This does more than put that back: of the 6,455 programs of `test/`, `test/share` and `test/reject` compiled under the flag, the C or the refusal of 191 changes, and each was run on master and here. 14 are right again, as they are with that change's answer for a receiver with no type put back (on master 3 do not build, 7 are refused, 4 print something else), 3 that are not right that way either now print under the flag what their plain build prints (`test/issue_3342_threads_with_native_packages.rb` dies with a segmentation fault, `test/literal_string_markers.rb` is refused, `test/implicit_conversion_protocol.rb` does not raise one of its TypeErrors), the other 174 print what they print on master, none is lost. One refusal becomes an abort the plain build already has: `test/multi_assign_operand_gc_root.rb`, refused under the flag on master, builds here and at `SPINEL_GC_STRESS=2` aborts in the collector's check, as master's plain build of it does; it is right with the stress unset and at 1. `make share-strings-test` could not show any of it: it runs `test/share`, `test/share_strings_*.rb` and the rejects of `test/share/reject.list` under the flag, and these 17 are plain tests.

The share walk read every method, also one no call reaches. Codegen emits no C for such a method and its locals are never given a type, and since that change a call on a receiver with no type is one the walk does not follow. So the `buf << x` of `__enumw_each_slice` (`builtins/enumerator.rb`, spliced with the chained iterator, called by nothing here) put an in-place change among the Strings of every call the walk does not follow, and each String that met such a call became a handle. A method of the program's own that nothing calls did the same (`def chg = @k[0] << "?"`).

The walk now leaves out a method no call reaches. Reachability goes by name and is computed before the fixpoint and again after it, so a method that a call the walk reads reaches is read whatever its mark says: a pass writes `e.map { break }` as a call to `__enumw_map` in between, and without that 20 of the programs above lost facts about a method that is called.

Not here: `test/bundle_classd_27.rb` is refused under the flag since that change and still is. With that change's answer put back it prints as CRuby. Its call on a receiver with no type, `receiver.data["name"]` with `receiver` one of two sibling classes, is in the main program, which is reached.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`test/share/share_strings_unreached_method.rb` is written from CRuby 3.3.6; its 4.0 run is owed)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
