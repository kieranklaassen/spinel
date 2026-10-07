<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that a reopening of a builtin exception class defines, called on an exception made for the call, reads another object's fields in a plain run: 11 of 50,000 here.

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
p bad     # master: 11. CRuby: 0
```

For such a method `emit_call_exception_arms` (`src/codegen_call_exception.c`) binds the receiver to a C temporary and calls the method with it. Nothing held an exception made for the call (`RuntimeError.new("r").checked`, a method's answer): a collection inside the method freed it, and what the method allocated next took its place. The temporary is now rooted where the receiver's expression can allocate; a local or an instance variable keeps its C.

Cost, by callgrind on master 4f8b737c: a reopened method that answers `message.size`, called 1,000,000 times on `made(i)`, takes 1,434,798,727 instructions before and 1,450,799,851 after, 16 a call; called on a local, its C is identical. `tools/cident.sh` against that master: 6,404 identical, 3 differ, 0 refusal changes, of 6,407: this test, `test/exception_base_reopen.rb` and `test/exception_reopen_override_order.rb`, which call such a method on a new exception.

The new test joins `GC_STRESS_TESTS`. `test/exception_base_reopen.rb` under `SPINEL_GC_STRESS=2` prints freed bytes for its class names on master and then dies, for this cause and for a second one in `sp_str_dedup` (its `self.class.name`). With this change alone it prints the freed bytes and exits 0, so this stands above the fix of `sp_str_dedup`; with both it prints its `.expected`. It is not added here: at level 1 it prints `MyError` for `RuntimeError` on master and with both, a third cause.

Depends on the pull request "sp_str_dedup roots the String it copies while the copy is allocated".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
