<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Token
  def initialize(n) = @n = n
  def object_id = @n * 10
end
p Token.new(4).object_id     # 40 in CRuby
```

prints the object's address on master: the builtin arm answers for any receiver. With an own `__id__` that answers a String, `puts t.__id__` ends in a segmentation fault.

The arm already stands down for a generated reader of the name, in the inference (`infer_universal_call`) and in the emitter (`emit_call_identity_arms`). It now stands down for any member of the receiver's class, a def as well as a reader: its own, an inherited one, an included module's, a Struct block's, as `display`'s arms do. `__id__` goes with `object_id`. The two conditions go from `== SP_MEMBER_ATTR` to `!= SP_MEMBER_NONE`; a class with neither name resolves no member and keeps its C.

Not in this change: a boxed receiver takes the builtin whatever it holds.

`test/own_object_id.rb` prints 16 lines; on master its C does not build. CRuby warns on stderr against redefining `object_id` and `__id__`; its stdout is what is compared.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
