<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
S = Struct.new(:x)
c = S.new
c.x = +"q"
c.x << "z"
p c.x
```

prints `"qz"` in CRuby and stopped in the C compiler on master: `incompatible type for argument 1 of 'sp_String_append_bin'`. So did an `attr_accessor` filled by its setter after `new(nil)`, and a member that holds a String or an Integer. The reader's read is marked to hand out its ivar's handle (#6179), while the slot itself settled as a boxed value, so the read is an `sp_RbVal` where every consumer of the mark takes an `sp_String *`.

This is on the ground of CONTRIBUTING.md's "Mutable Strings (#6179, #6765)": it adds no sharing rule. The String sits in that slot by value, so the change could only reach a copy, and the read is refused by name, with three `test/reject` programs, their records and a limits entry:

> the String read from member `x` is changed in place, and member `x` is a boxed slot (it holds nil or a value of another class as well, or the String it is given is itself boxed): the String sits in that slot by value, so the change would reach a copy of it (a String is not yet shared by reference in a boxed slot). Change the String before it is stored.

**Checked** on c6bbdfbc9 against CRuby 3.3.6 run with `--enable-frozen-string-literal`; the reject programs were run again under CRuby 4.0.7:

- 864 programs that change a String through the reader of a slot filled with nil, an Integer or a Symbol as well. This commit refuses 176 of them, on this branch and alone on master alike, and each of the 176 is a C error on master. No program that built on master is refused. The whole set, against master:

  | the 864 | this branch (above the first pull request) | this commit alone on master |
  |---|---|---|
  | a C error on master, refused | 416: 240 by the first pull request, 176 by this commit | 176 |
  | refused on master, now in the first pull request's words | 48 | 0 |
  | refused on master, in the same words | 48 | 96 |
  | generated C byte-identical | 352 | 592 (240 of them the store's C error, the first pull request's ground) |

- `make cident REF=c6bbdfbc9`: 6056 identical, 0 differ, 0 refusal changes, on this branch and for this commit alone on master.
- `tools/refusals.sh`: pass, 442 records above the first pull request (432 on master alone; master has 426). `make reject-test`: pass.
- The advice the sentence prints, applied to the three reject programs: each then builds and answers as CRuby at `SPINEL_GC_STRESS` unset, 1 and 2.

**Left alone**

- The same read on implicit self in a method of the Struct's own block is written by another arm and is still the C error it is on master:

  ```ruby
  S = Struct.new(:x) do
    def chg = x << "z"
  end
  c = S.new
  c.x = +"q"
  c.chg
  ```

- An ivar that sees nil before it is promoted stays the nullable handle it was and still compiles (`K.new(nil)` beside `K.new(+"q")`).

No function over 1,000 lines grows: `emit_object_call` 841 to 843; `emit_call_body` is untouched.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7; the three new programs are under `test/reject` and have no `.expected`: CRuby 4.0.7 with that flag runs each and prints what 3.3.6 does)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
