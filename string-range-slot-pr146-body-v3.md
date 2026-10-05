<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
S = Struct.new(:r)
def fill(c, i)
  a = "a#{i}"
  z = "z#{i}"
  c.r = (a..z)
end
c = S.new(("a".."z"))
warm = (1..5000).map { |k| "warm-#{k}" }
i = 0
while i < 200
  fill(c, i)
  junk = (1..3000).map { |k| "j#{k}" }
  r = c.r
  puts "#{i}: #{r.first}..#{r.last}" unless r.first == "a#{i}" && r.last == "z#{i}" && junk.size == 3000
  i += 1
end
puts "done"
```

printed `59: j319..j320` and `110: j240..j241` before `done`, in a plain run with gcc and with clang. CRuby prints `done` alone. With `SPINEL_GC_STRESS=1` 197 of the 200 turns read another String's bytes, and level 2 stopped at "the mark reached a freed heap string". With `SPINEL_GC_MINOR=0` the program was right.

A String Range sits in its slot by value and carries two GC strings. `class_needs_scan` counts such a slot (#4353), so the object marks both ends, but `wb_field_is_ref_in` asked `needs_root` alone, which says no for a slot that is not itself a reference. The store took no write barrier, a minor mark did not walk the old object, and the sweep freed both ends while the slot still named them.

The scan and the barrier now ask one predicate, `ivar_holds_ref`, so the store is followed by `sp_gc_wb` as a String's is. The same holds for an instance variable written in a method, through `attr_accessor` or in `initialize` after something else was allocated: each lost its ends the same way. While the caller still held the ends (`h.put(a, z)` and the read in one loop body) the instance variable was right before, by the caller's rooted argument temps.

Not changed, and as on master:

- Ends made in the store itself, `s.r = ("a#{i}".."z#{i}")`, are lost before the store is reached. That is the piece this one depends on. Without it they still stop at level 2, and of 114 such programs 27 print at level 1 what master prints for them with `SPINEL_GC_MINOR=0`: for 26 that is another wrong line than master's, and one (`include?` after an `initialize` that allocates first) was right on master at level 1 while the freed end's bytes still stood, and answers `false` here. With that piece beneath, the one is right at every setting, and 93 of the 114 are right at all five with gcc, 90 with clang.
- A store whose value is used and comes from a call (`h.r = mk(i)` as a method's last expression, `x = h.r = mk(i)`, `use(h.r = mk(i))`) and `instance_variable_set(:@r, mk(i))` keep the form master writes for them, with no barrier, and still lose the ends: wrong at level 1 and stopped at level 2, on master and here.
- A String Range in a global, a constant, a class variable or a class-level instance variable is marked by nothing; the global is wrong in a plain run.
- `inspect` of a String Range does not hold the text of its first end while it makes the second. At level 2, where master stopped before the read, a member that now keeps its ends reaches that fault and prints the wrong line the same Range prints from an Array element on master (see below). #<fork PR 51> cures it: with both, each such program is right at every setting.

Measured on master c6bbdfbc9, against CRuby 3.3.6, with gcc 13.3 and clang 18.1, in a plain run, under `SPINEL_GC_STRESS=1` and `2`, and with `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1` without and with level 1:

- 1,634 generated programs: 29 ways to store a Range (a Struct member by `=`, `[]=`, `send`, keyword `new`, multiple assignment; an instance variable, an accessor, `instance_variable_set`; an Array element, a Hash value, a captured local, a global and others), four String and four other kinds of Range, thirteen reads. 710 get master's C, among them every Range that is not of Strings and every slot that is not a member or an instance variable. In the other 924 each changed line carries the barrier.
- Right at all five settings: 475 on master, 1,312 here, the same with both compilers. Of 8,170 runs a compiler: 4,920 right on both, 2,144 not right on master and right here, 998 the same and not right, 108 the `inspect` ones below. Right on master and not right here, among these 1,634: 0.
- The 114 programs whose ends are made in the store itself are a second kit, not among the 1,634, and are counted apart. Of their 570 runs a compiler, without the piece this depends on: 301 right on both, 53 not right on master and right here, 189 the same and not right, 26 another wrong line than master's, and 1 right on master and not right here, the program named above, at level 1. In a plain run that count is 0. With that piece beneath it is 0 at every setting (with gcc).
- 54 programs, all of them `inspect` of a String Range in a member or an instance variable, abort on master at level 2 and print a wrong line here with exit 0, and at level 1 print another wrong line than master's. For each the line is byte for byte what master prints for the same program at the same level with `SPINEL_GC_MINOR=0`, and at level 2 what it prints for that `inspect` on an Array element: the Range is whole, `sp_srange_inspect` loses its own temporary.
- `make cident REF=c6bbdfbc9`: 6055 identical, 3 differ, 0 refusal changes. The three are `range_dup_unfrozen`, `str_range_endpoints_root` and the new test, by the barrier on each such store. Both older tests print what they printed at every setting.
- Cost (callgrind): a store pays 11 instructions, what a String member's store pays. 2,000,000 member stores 172,668,600 to 194,668,623; a loop that makes two ends and stores them, 300,000 turns, 160,820,468 to 164,137,847 (+2.1%). With `--no-write-barrier` the count is master's. Where the store's class is not known the barrier goes by the slot's name, as it does on master for a String: an Integer `@r` in one class beside a String Range `@r` in another pays it too, 22 instructions a `new` (300,000 of them, 22,730,512 to 29,330,524; master runs 29,396,334 when the other `@r` is a String).
- `make gc-minor-test` and `make gc-stress-test` pass; without the change the new test fails the first with "a holder the barrier did not record". `tools/refusals.sh` passes. `make scale-test` gives master's four numbers (1.71x, 4.73x, 6.08x, 4.22x).

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 94> (ends made in the store itself are lost before the store, and one program of that form that master had right at level 1 is right here only with it beneath)
