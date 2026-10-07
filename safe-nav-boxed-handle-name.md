<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Tok
  attr_reader :string
  def initialize(s) = @string = s
end
t = [Tok.new("ab"), nil][ARGV.size]
p t&.string
```

- Before "A boxed MatchData answers string": `"ab"`.
- Now: it does not build (`incompatible types when assigning to type 'sp_RbVal' from type 'const char *'`).
- CRuby: `"ab"`.

`string` is one of the names a MatchData read out of a container answers since that change. `pre_match`, `post_match`, `captures`, `begin(n)`, `end(n)`, `offset(n)`, `byteoffset(n)` and an Enumerator's `with_index`, `next_values` and `peek_values` are the others. Behind a `&.` none of them builds: not on the handle itself (`m&.begin(0)`, `m&.pre_match`, `e&.with_index(1)`), not on an object of the program's own class that has a method of the name, as above, and not on a StringScanner (`s&.string`). The last two were right before those changes. An Addrinfo's `a&.ip_port` did not build before them either.

The cause is one disagreement. Under the `&.` guard, and in the builtin arm of a dispatch, codegen renders such a name on the unboxed handle, in the handle's C type. The inference types the call poly, because `infer_last_resort_call` answers a `&.` call before it reaches the boxed handle rule. So the slot is an `sp_RbVal` and the value an `sp_int`, a `const char *` or an array.

Now the `&.` rule asks the handle rule first, and the call has the type the handle answers: `m&.begin(0)` is an Integer, nil for a nil. Where a native class's method of the name stands the handle rule down (`StringScanner#string`), the builtin arm of the dispatch has no answer, as for a `.` call.

Two commits. The first moves the handle rule into `infer_boxed_handle_call` and changes no generated C (`make cident REF=a39414338`: 6369 identical, 0 differ). The second is the fix.

Not here:

- `&.regexp` still does not build. A Regexp's C slot has no nil the guard can use: `m = "x".match(/q/); p m&.regexp` prints `//` on master.
- `a&.ipv4?`, a predicate of a boxed Addrinfo, still does not build (`'_sn_2' undeclared`). That is another arm of the guard.
- In a program that loads strscan, `m&.string` on a boxed MatchData raises NoMethodError, as `m.string` does there.

Tests: `test/safe_nav_boxed_handle_method.rb`, 35 lines, and `test/safe_nav_boxed_handle_name_own_method.rb`, 16 lines. Neither builds on master.

Generated C against master (`make cident REF=a39414338`): 6369 identical, 2 differ, 0 refusal changes. The two are the new tests. optcarrot's generated C is byte-identical.

50 small programs written for this change (each name behind a `&.` on the handle, the receiver nil and not; chains; a class of the program's with a method of the name; a StringScanner; an Addrinfo; the same names with a `.`), with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 30 are right in all six before the three changes that added the names (06064727f), 8 on master, 45 here, and none loses a cell against master. The five that are not right are the three kinds above and a `.string` on a boxed MatchData beside a StringScanner, which raises on master too.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
