<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Box
  attr_reader :b
  def initialize = @b = +"b"
end
k = Box.new
t = k.b << "a" << "a" << "a"        # 17 links in all
p k.b.size, t.size, t.equal?(k.b)   # 18, 18, true in CRuby; 2, 18, false on master
```

16 links are right. `t = obj.buf << x` keeps in `t` the String the reader hands out, and the pass that says so (the last loop of `promote_shared_stored_strings`) marks each append of the chain to emit the handle. It kept the links in an array of 16 and stopped walking when the array was full. What it had reached was then a link and not the reader, so the chain was left unmarked whole: `t` took a copy, and the reader's String kept the first link only.

The links are now counted on the way down and walked again to be marked. What was chosen: only a chain of `<<` and `concat` links is marked whole. One holding a `prepend`, a `replace` or a `clear` keeps the walk of 16 and is master's C byte for byte, because a marked link of those renders its receiver twice and each such link doubles the compile.

From 17 links the kept local is a handle, as it is at 2 to 16, and two uses of it go from compiled to refused with that:

```ruby
t = k.b << "a" << "a" << "a"    # 17 links or more
t += "x"                        # unsupported operator assignment
case "zz"
in t                            # a String bound by a pattern to a local that is appended to ...
  p t
end
```

Master refuses the first at 2 to 16 links, and the pull request this depends on refuses the second there, where master's C does not build. From 17 links master compiled both, `t` being a copy: right where the reader's String is not read again (14 of the 648 programs below), wrong where it is (`p k.b.size` after either prints 2 for 18). The root may be a reader, an accessor, a reader of a reader or a Struct member.

Not changed: a named capture and a `for` variable onto the kept local do not build, as at 2 to 16 links; the statement `k.b << "a" ...` loses its links from 65, and `t = @b << "a" ...` loses one from 66 (the chain's own walk of 64).

Tests: `test/string_reader_append_chain_long.rb` has seven chains of 20 links and one of 100; 18 of its 22 lines differ on master.

Generated C against the commit under this one (`make cident`), on master 06064727: `6334 identical, 1 differ, 0 refusal changes` (the new test). `tools/refusals.sh` passes (532 records). optcarrot's generated C is byte-identical. Programs, with CRuby 3.3.6 as the reference and the commit under this one as the base: 648 at 2 to 100 links (54 uses of the kept local, 8 kinds of link, 18 patterns). 279 that are wrong are right. 60 that are wrong are refused and 24 that are wrong do not build, each as at 2 to 16 links. 14 that are right are refused, the two uses above. 7 that are wrong print another wrong line (`t = nil` before the chain, as at 2 to 16 links). The other 264 are the same.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers, a String, true and Arrays of them)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "A pattern's binding onto a String local that is appended to is refused by name"
