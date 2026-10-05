<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = "qr".dup
t = s
t.freeze
l = -> { t << "x" }
begin
  l.call
rescue FrozenError => e
  p e.class             # FrozenError
end
p s.frozen?             # true
```

Before: this did not build (`'lv_t' undeclared`), with the `freeze` outside the proc as above or inside it (`l = -> { t.freeze; 1 }`).

After: it builds and prints what Ruby prints, and the String is frozen through either name.

It also cures a wrong answer. A parameter a proc captures has a C local of that name, so the program built, but the local is stale once the parameter is assigned again, and `freeze` froze the String the caller passed:

```ruby
def m(s)
  t = s
  l = -> { s << "x"; s }
  s = +"new"
  s.freeze
  begin
    p l.call
  rescue FrozenError => e
    puts e.message      # can't modify frozen String: "new"
  end
  p s, t.frozen?        # "new", false
end
m(+"old")               # master: "newx", then "newx" and true
```

The statement arm of `freeze` froze a shared String local through `lv_<name>`. A local a proc captures is in its cell, so that C local is not there. The arm now takes the handle through `emit_local_ref`, which reads the cell or the capture. `freeze` in value position already went through `strbuf_slot_ref` and is unchanged. Six lines in `src/codegen_stmt.c`; no String is shared that was not shared before.

Measured with both compilers built on 5c2dea5154f8 (Linux x86-64, gcc 13.3 and clang), CRuby 3.3.6 with `--enable-frozen-string-literal` as the reference:

- 79 programs that freeze a captured String on one side of a proc and change it on the other: 15 are right on master and 64 do not build; 43 are right with the change, at plain and at `SPINEL_GC_STRESS=1`. The other 36 still do not build, each for a `slice!`, `setbyte`, `insert`, `[]=` or `clear` on the captured String, which this change does not touch.
- Of 1,149 programs about a captured or shared String, the generated C of 81 changes: 32 go from no build to right, 42 do not build before or after, 7 are right before and after. None is right on master and wrong or refused with the change, and none goes from no build to a wrong answer.
- `make cident REF=5c2dea5154f8`: `6078 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The one is the new test, for which master writes C that does not compile.
- `test/captured_string_freeze.rb` does not build on master. With the change it prints its `.expected` with gcc and clang, with `--int-overflow=promote`, and under `SPINEL_GC_STRESS=1` and `2`. The `.expected` was written with CRuby 3.3.6 run with `--enable-frozen-string-literal`; CRuby 4.0.7 with the same flag prints it byte for byte.

Left alone, the same before and after:

- A position mutator (`slice!`, `setbyte`, `insert`, `[]=`, statement `clear`) on a String a proc captures does not build (`'lv_t' undeclared`).
- Four of the 79 programs (a parameter a lambda appends to, frozen in the method, the lambda returned) abort at `SPINEL_GC_STRESS=2` on master and with the change, and are right at plain and at level 1 on both.
- `FrozenError#receiver` is not `equal?` to a String that has two names. Master answers the same with no proc (`s = "q".dup; t = s; t.freeze; begin; t << "x"; rescue FrozenError => e; p e.receiver.equal?(t); end` prints false), and a program that now builds can reach it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
