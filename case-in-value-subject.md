<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A pattern match on an object kept by value bound a freed String when `deconstruct` allocated before it read the String.

```ruby
class Name
  def initialize(i) = @s = "#{1000 + i} " * 300

  def deconstruct
    t = "x" * 300              # a collection here frees the subject's String
    u = "y" * 1500             # and this takes its place
    [@s, t, u]
  end
end

def mk(i) = Name.new(i)

def first_of(i, want)
  case mk(i)
  in [q, t, u]
    q == want ? 0 : 1
  else
    1
  end
end

bad = 0
i = 0
while i < 3000
  bad += first_of(i, "#{1000 + i} " * 300)
  i += 1
end
p bad
```

Master (2801817b8) prints `5` in a plain run, built with gcc or clang. CRuby prints `0`.

`Name` is never written, so it is kept by value: the struct lives in the C temp `emit_case_match` binds the subject to, and for a subject made in place that temp is the only holder of `@s`. The match rooted its subject with `emit_gc_root_tmp`, which takes nothing for a by-value object (rooting the struct as a pointer would be wrong), so the line was empty:

```c
sp_Name  _t6 = sp_mk(lv_i);

{
  sp_StrArray * _t8 = sp_Name_deconstruct(_t6);
```

It now calls `emit_gc_root_tmp_refs`, which roots a by-value object's String fields one by one, the way a local of that class is rooted, and roots anything else as `emit_gc_root_tmp` did:

```c
sp_Name  _t6 = sp_mk(lv_i);
_gcf.p[4] = SP_GC_ENTRY_PTR(_t6.iv_s);
```

`mk(i) => [q, t, u]` and `mk(i) in [q, t, u]` are case/in by the time they are emitted, and `deconstruct_keys` reads the same temp, so one line covers them.

Cost: one root for each String field of a by-value subject. Callgrind, 200,000 matches:

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| `case mk(i) in [q, t]` | 122,709,875 | 123,565,112 | 129,061,202 | 130,118,237 |
| `case mk(i) in { s: String => q }` | 269,074,414 | 271,209,485 | 267,948,528 | 269,294,622 |
| the subject in a local, `case v in [q, t]` | 123,965,373 | 124,972,707 | 130,518,494 | 131,924,700 |
| a by-value subject with no String, `in [a, b]` | 72,843,347 | 72,843,347 | 74,323,624 | 74,323,624 |

That is 4 to 11 instructions a match. A subject read from a local is rooted too, as a pointer subject is on master. Of the 6,376 programs of `test/`, `benchmark/` and the packages' tests, only the new test changes its C; optcarrot's C is the same.

Not in this change, and as on master: a by-value class whose `initialize` builds two Strings loses the first while the second is built, whatever is done with the object afterwards. The test's class has one String.

Test: `test/case_in_value_subject_string_root.rb`, nine lines, each the number of 3,000 matches that bound another String: an array pattern, the same with classes, a case/in read for its value, `=>`, a pattern that names the class, a subject made by `new`, a hash pattern, a hash pattern that names the class, `in` as a condition. On master it prints 7, 7, 7, 7, 7, 8, 6, 8, 7 in a plain run, built with gcc or clang.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 2801817b8)
- [ ] Depends on: # (nothing)
