<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that a reopening of a builtin exception class defines, called on an exception made for the call, reads another object's fields in a plain run. Such a call pays 16 instructions with gcc and 18 with clang; a call on a local or an instance variable keeps its C.

```ruby
class StandardError
  def checked
    other = RuntimeError.new("zz" + message.size.to_s)
    other.message.size > 0 ? message : ""
  end
end
def made(i) = RuntimeError.new("m" + i.to_s)
bad = 0
i = 0
while i < 50_000
  bad += 1 unless made(i).checked == "m" + i.to_s
  i += 1
end
p bad     # master: above 0. CRuby: 0
```

For such a method `emit_call_exception_arms` (`src/codegen_call_exception.c`) binds the receiver to a C temporary and calls the method with it. Nothing held an exception made for the call (`RuntimeError.new("r").checked`, a method's answer): a collection inside the method freed it, and what the method allocated next took its place. The temporary is now rooted where the receiver's expression can allocate.

Cost, by callgrind on master 3d629868: a reopened method that answers `message.size`, called 1,000,000 times on `made(i)`, takes 1,564,680,499 instructions before and 1,580,680,498 after with gcc, and 1,448,154,956 and 1,466,153,835 with clang; called on a local, its C is identical. `tools/cident.sh` on that master: 6,495 identical, 3 differ, 0 refusal changes, 0 refused by both, of 6,498: this test, `test/exception_base_reopen.rb` and `test/exception_reopen_override_order.rb`, which call such a method on a new exception.

The new test joins `GC_STRESS_TESTS`. `test/exception_base_reopen.rb` dies under `SPINEL_GC_STRESS=2` on master for this cause; with the change it prints its `.expected`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
