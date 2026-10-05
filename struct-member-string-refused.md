<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
S = Struct.new(:x)
c = S.new("q".dup)
c.x << "z"
p c.x
```

prints `"qz"` in CRuby and stopped in the C compiler on master: `initialization of 'sp_String *' from incompatible pointer type 'const char *'`. A Struct or Data member whose String the program changes in place is the shared handle (#6179), and `new`, `S[...]`, `super`, a bare `new` in a class method of the Struct and `Data#with` wrote the `const char *` the argument renders as into its `sp_String *` slot.

This is on the ground of CONTRIBUTING.md's "Mutable Strings (#6179, #6765)": it adds no sharing rule and converts no String. The store is refused by name, with five `test/reject` programs, their records and a limits entry:

> a String is stored in member `x` of a Struct, and that member holds a shared String (the program changes its String in place, or stores in it a String it changes elsewhere): the member would hold a copy of this one (a String is not yet shared by reference into a Struct member). Give the member a new String instead of changing it in place (`obj.x += "z"`), or store a copy of the String changed elsewhere (`s.dup`).

**Checked** on c6bbdfbc9 against CRuby 3.3.6 run with `--enable-frozen-string-literal` (4.0 is not installed where this was written):

- 4,760 programs (17 ways to build the object, 28 arguments, 8 ways to change the member, at the top level, in a method and in a block): 3,900 are refused and each of them is a C error on master; the generated C of the other 860 is byte-identical.
- `make cident REF=c6bbdfbc9`: 6056 identical, 0 differ, 0 refusal changes.
- `tools/refusals.sh`: pass, 436 records (master has 426; five new programs in two overflow modes). `make reject-test`: pass.
- The advice the sentence prints, applied to the five reject programs: each then builds and answers as CRuby at `SPINEL_GC_STRESS` unset, 1 and 2. Four need its first piece (`c.x += "z"`). `test/reject/data_member_string_with.rb` has both reasons at once and needs both pieces: `e = e.with(x: e.x + "z")` in place of the append, and `D.new(x: s.dup, n: 1)` at the store that first filled the member, which is the line above the one the refusal names (the `with`). Either piece alone leaves it refused.

**Refused though it built on master**: a `fetch` as the member's value.

```ruby
S = Struct.new(:x, :n)
a = [+"s", +"t"]
begin
  d = S.new(a.fetch(5), 2)
  d.x << "z"
  p d.x
rescue IndexError => e
  puts e.class
end
```

Master's C for the `fetch` is a conditional the C compiler lets into the slot. The binary prints `IndexError` as CRuby does; with `a.fetch(0)` (CRuby `"sz"`) it dies with signal 11. Both are refused here. 19 programs of this kind whose `fetch` always raises are the only ones found that built and answered right on master and are refused. Master refuses the same value through the setter (`c.x = a.fetch(5)`: "an attribute writer given a String, which no conversion keeps in its sp_String * slot").

**Left alone**

- The conversion that would make these programs right: a read through the member's reader still hands out a copy wherever the analysis did not mark it, so it waits for Strings shared by default.
- `S.new(*a)`: builds on master and loses the change, as before.
- A Struct whose own `initialize` takes the arguments, and `**hash`: as on master.
- Under a silent emittability probe the store is written as it was.

No function over 1,000 lines grows: `emit_super` 461 to 464, `emit_struct_recv_call` 679 to 680, `emit_call_class_method_arms` 521 to 522; `emit_call_body` is untouched.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7; the five new programs are under `test/reject` and have no `.expected`: CRuby 4.0.7 with that flag runs each and prints what 3.3.6 does)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
