<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Page
  attr_reader :text
  def initialize(t) = @text = +t
end
w = Page.new("t")
p(w.text << "1" << "2")   # "t12"
p w.text                  # "t12" in CRuby, "t1" on master
```

The second link is appended to a copy, with nothing said. So is every link after the first where the chain stands after `return`, as a receiver (`(w.text << a << b).size`), an operand, an argument, in an interpolation, with `concat(a).concat(b)`, and on an attr_accessor or a Struct member. So are the links of a chain of 65 or more as a statement, and of 17 or more under a local write. The same chain as a method's last expression does not build:

```ruby
def add(pg)
  pg.text << "a" << "b"   # returning 'sp_String *' from a function with incompatible return type 'const char *'
end
```

An append on a reader's String works on the handle the reader hands out, and answers that handle only where it is marked to. The mark was given to the links of a chain under a local write (`r = obj.buf << x << y`), to 16 of them. Anywhere else the first link answered the String read, and the next one concatenated onto that; a statement's chain is appended link by link without the mark, to 64 of them.

A link that is the receiver of another append is now marked wherever the chain stands; the last link still answers the String read. In tail position such a chain is left to the value path, which runs the base once and answers the handle's text: the tail arm emits the base again after the chain, which here is the handle itself. The two go together: left to the value path without the mark, the last-expression chain would build and lose its later links.

Not here, each as on master. The String such a chain answers from a method is the reader's text, not the reader's String: `s = add(pg); s << "!"` leaves `pg.text` as it was, as it does after one link (`pg.text << "ab"`). Under `SPINEL_GC_STRESS=2` a run of appends on a reader read as values faults on the GC mark path, with one link on master and with two here. An append onto a reader whose answer is nil at run time (`Page.new` with `@text = nil`) does not raise NoMethodError.

Tests: `test/string_append_chain_reader_value.rb` has the chain as a method's last expression (on a bare reader, on `self`, on another object, under a condition, as a `begin` block's value, on a base that runs code), after `return`, as an argument, a receiver, an operand and in an interpolation, 65 links as a statement and 17 under a local write. On master it does not build; where a chain's value is read, the reader's String is printed afterwards without the later links.

Generated C against master (`make cident REF=5c78f07e`): `6414 identical, 1 differ, 0 refusal changes` (the new test). `tools/refusals.sh` passes (536 records). optcarrot's generated C is byte-identical. Programs of ours, on master 5c78f07e with CRuby 3.3.6 as the reference: 455 chains of 1 to 3 links (eight kinds of receiver, twelve places the value is read, `<<` and `concat`, a String and an Integer argument). 132 that lose links on master are right; the 323 that are right on master keep its C byte for byte. And 297 chains of 2 to 300 links on a reader, an accessor, a Struct member and a local (as a statement, read as a value, under a local write, as a last expression): 171 are right now, 150 that lost links and 21 that did not build; the 121 that are right on master and 5 that are wrong keep its C. The 5 are a local's chain of 64 links or more under a local write (`v = s << ...; v << "!"` does not reach `s`). A chain of 1,000 links on a reader compiles in 18.0 s for master's 39.8 s, cc included.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Strings, Integers, true and an Array)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
