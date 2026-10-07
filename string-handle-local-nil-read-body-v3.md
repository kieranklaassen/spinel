<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String local held as a handle (two appends in a row, or one in a loop) died with SIGSEGV when it was read while nil. The change is in the nil analysis (`an_nil_facts`) and one condition at the handle's read. It adds nothing to the code generator's nil helpers.

```ruby
def find(k) = k > 5 ? +"hit" : nil

def run(k)
  s = find(k)
  i = 0
  while s && i < 2
    s << "!"
    i += 1
  end
  s
end
p run(9)     # "hit!!"
p run(1)     # master: SIGSEGV. CRuby: nil
```

```ruby
if ARGV.size > 5
  t = +""
  t << "a"
  t << "b"
end
p t.size     # master: SIGSEGV. CRuby: NoMethodError
```

Nil is a NULL handle. The local read in `emit_local_ivar_write_expr` copies `sp_String_cstr(t)` and tested the handle only for a parameter, a dynamic handle and a shared one; it now tests it wherever the nil fact says the local may be nil (`Repr.may_nil`), so the loop's test and the method's value above read nil, and `t = nil; p t` prints nil. The fact's definite-assignment seed in `an_nil_facts` skipped a `TY_STRBUF` local, so a handle read before its first write had no fact and a call on it no nil target; the seed now covers it, and `t.size` raises NoMethodError as it does for a handle assigned nil. A local the fact proves not nil keeps its C.

The read stays untested where its nil would be past a NoMethodError the build does not raise. The call plan guards a call for a nil the program writes, not for one it cannot bound (a slice or a pick that missed). There `t << "x"` does nothing on the NULL handle, and `t < "a"` compares a NULL: a nil read after the one, or as the receiver of the other, would turn the crash into a wrong answer. `an_nil_facts` marks those reads (`nil_fact_unraised`), by the plan's own answer for the call, and they keep master's C.

```ruby
def tail(s)
  t = s[10, 2]
  return "none" if t.nil?   # master: SIGSEGV on a miss. Now: none
  t << "a"
  t << "b"
  t
end
```

A guard that does not hold lets the same append run, so a local behind one keeps master's C at every read. The fact takes three such guards: a write in a condition after the part that proves (`return if t.nil? || (t = nil; false)`); the body of a loop that tests after it (`begin ... end while t`), which runs once untested; and any guard in a program that defines what one is made of. `fail("empty") if t.nil?` is read by its names: where the class has its own `def fail` the call returns, CRuby raises at the append, and master dies at the read. So in a program that defines `raise`, `fail`, `exit`, `abort` or `throw` (a def, an alias, an attribute, a Struct member, a name given to `define_method`), or a `nil?`, `==`, `!=`, `!`, `is_a?`, `kind_of?` or `instance_of?` a String could answer, no handle local's read is tested (`nf_guard_redefined`). Master's analysis takes the same guards by name for every other local; that is its own and is not changed here.

An append under another link of a chain (`t << a << b`) is emitted with no nil arm, whatever the plan says of it: the statement emitter appends each link on the handle. A local appended to that way keeps master's C at every read (`nf_append_chained`).

An append that is its body's value had no nil arm either, and that is why this stands above "An append that is its body's value raises on a nil String handle". Without it this change alone turns a crash into an answer:

```ruby
def add(x)
  t = +""
  t << "a"
  t << "b"
  t = nil if x.empty?
  t << x     # the method's value
end
p add("")    # master: SIGSEGV. This change alone: nil. With both, and CRuby: NoMethodError
```

Cost, by callgrind on master ae2c38c7, only for a local the fact says may be nil: 1 instruction more an append and a value read, 2 more a call (the guard). Any other local pays nothing. The compiler itself takes 0.06% to 0.17% more instructions on five programs.

`tools/cident.sh` against the pull request this depends on, on master 8dc55225: 6,443 identical, 5 differ, 0 refusal changes, of 6,448: this test, that pull request's test (the read after its append gains the test), and three tests where one such local's read gains the test or its calls the guard; each prints what it printed.

Not here: a program that defines one of those names keeps master's crash even where its guards hold, and so does a local with a chained append on a read that may be nil. An append on a local that may still be nil from a miss (`t = s[10, 2]; t << "x"; p t`) dies at the read as on master; CRuby raises NoMethodError at the append, and raising there belongs to the plan's guards. So does a call nil does not answer on such a local (`t < "a"`, `t + "x"`). `t.to_i` and `t.to_f` on a nil handle local still crash. Six uses that crashed now answer as a plain String local's nil does on master, which is not CRuby's answer: `p Array(t)`, `p [*t]` and `a = *t; p a` print `[nil]` (CRuby `[]`), `t.eql?(nil)` and `t.equal?(nil)` are false (CRuby true), and `s << t` appends nothing (CRuby TypeError).

Depends on the pull request "An append that is its body's value raises on a nil String handle".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
