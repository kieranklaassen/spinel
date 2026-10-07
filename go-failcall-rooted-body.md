<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

NoMethodError#args, and #receiver, of a failed call read a freed value when an argument or the receiver was made for the call. It shows under `SPINEL_GC_STRESS=2`; 1,000,000 plain raises of two shapes were right.

```ruby
b = [nil, 5][ARGV.size]
begin
  p b.slice(0..1)
rescue NoMethodError => e
  p e.args     # master at SPINEL_GC_STRESS=2: stops in the collector's check. CRuby: [0..1]
end
```

`sp_nomethod_msg_args` and `sp_stage_args_msg` (`lib/spinel_rt.h`) take the failed call's arguments as a C array and allocate the list for NoMethodError#args before anything holds them: an argument made for the call (a Range boxed, a String just built) was freed by a collection there, and so was a receiver a method had just returned. Both now root the array's slots, and `sp_nomethod_msg_args` its receiver, before the list is allocated, as the boxed `pow` arms root theirs at the call. The lines are added; nothing else in the header changes.

Cost: the path is the cold one of a call that raises. By callgrind on master 4f8b737c, 200,000 failed `b.slice(i..(i + 2))`, each rescued, take 1,165,109,418 instructions before and 1,171,329,889 after, 31 a raise; the generated C is identical. `tools/cident.sh` against that master: 6,407 identical, 0 differ, 0 refusal changes.

Not here: two new values in one failed call (`x.nope("a" + s, "b" + s)`, or a new receiver with a new argument) are still unheld under stress. The emitters box them into one C array, and the second is made while nothing holds the first; that is the emitters' change, not the runtime's.

`test/boxed_slice_receiver_checked.rb` stops under stress on master for this cause; it joins `GC_STRESS_TESTS` with the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
