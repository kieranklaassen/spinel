<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Hash value block binds copies of the stored Strings, so a block that appends to its value parameter is refused. A block that appends through a local assigned from the parameter slipped past the refusal, and the append went to the copy with nothing said:

```ruby
h = {}
h[:a] = +"ab"
h.each_value { |e| t = e; t << "z" }
p h   # {a: "ab"}; CRuby prints {a: "abz"}
```

The cost is compile time, on programs that are not refused: a value block that assigns its value to a local now pays the walk of its scope's calls that an Array block of that shape pays, which is 2% of a program of ten such blocks in one scope and 27% of one of a thousand (the counts are under "Compile time" below).

The Array arm of `promote_shared_stored_strings` asks `an_block_param_alias_mutated` for this shape (`a.each { |x| t = x; t << "!" }`). The Hash arm now asks the same question before it leaves a block alone. It is no new rule: the test, the refusal and the Strings it refuses are the ones that were there, and under `--share-strings` the route goes to `share_route_defer` as before. Covered with it: a chain (`t = u = e`), any change in place (`t.upcase!`) and a local handed to a method that appends, in `each_value`, `each`, `each_pair` and the iterators over `values`, `values_at` and `fetch_values`. The chained `each_value.with_index` was refused already.

Right programs refused: none of the repository's (cident below). Of 2,016 generated programs, 784 are newly refused, 422 were refused already and 810 keep master's C. Each of the 784 is refused by master once the local's name is swapped for the parameter's (`{ |e| e << "z" }`): 392 print a wrong answer on master, and 392 never read the Hash again, which master refuses in the direct form too. A local that is also assigned something else (`t = e; t = t + "x"`) or a copy (`t = e.dup`) is no alias and keeps master's C. Under `--share-strings` all 2,016 keep master's C, and the 784 print CRuby's answer there.

Not here: `transform_values` and the other Hash iterators that bind the value are not on the refusal's list, with or without the local. A local of the enclosing scope (`t = nil` ahead of the block), a value kept in an Array that is appended to later, a multiple assignment (`t, n = e, 1`) and a conditional alias (`t = c ? other : e`) are not followed.

Compile time: a value block with no such local adds 33 counted steps to a whole program. One with the local pays what an Array block of that shape pays on master, a walk of its scope's calls. K methods with one such block each add about 330 steps a method (0.3% at K = 1000). K such blocks in one scope add 2% at K = 10, 8% at K = 50 and 27% at K = 1000, where master's own count grows with the square of K as well. Summed over the 6,260 test and benchmark programs the count is 0.0003% higher; the largest rise on one program is 0.13%.

## `make gate` (on this branch merged with current master)

```
cloud container, CRuby 3.3.6: the full gate is owed on a machine with Ruby 4.0
cident: 6418 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against 9274c732e)
refusals: pass (538 records)
reject-test: pass
share-strings-test: pass
scale-test: instance_eval forwarding work at 2x the wrappers is 1.71x (limit 2.50)
scale-test: work at 4x the program is 4.74x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.13x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.17x (linear 4.00, limit 4.50)
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the one new test is a refused program in test/reject and has none)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (optcarrot is not in this container; the C of every repository program is unchanged)
- [ ] Depends on: # (nothing)
