<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

An attribute writer called on a boxed receiver raised NoMethodError for a writer the receiver has, when the value is of a subclass of the slot's class:

```ruby
class Node
  attr_accessor :left, :right
  def link_right(node)
    @right.left = node      # undefined method 'left=' for an instance of Column (NoMethodError)
    @right = node
  end
  def initialize
    @left = self
    @right = self
  end
end
class Column < Node
  def initialize(name)
    super()
  end
end
root = Column.new("root")
root.link_right(Column.new("a"))
```

Here `@right` is boxed, `@left` has settled as `Node` and `node` is a `Column`. CRuby runs it and prints nothing.

`emit_boxed_writer_arms` switches over the receiver's class and gives an arm to each class that has the writer, leaving out a class whose slot could not hold the value: one whose type is not the value's own, unless either is boxed. A slot typed as an ancestor of the value's class does hold it and was left out with the rest, so the switch had its default alone, the raise:

```c
switch (_t1.tag == SP_TAG_OBJ ? _t1.cls_id : 0x7fffffff) { default: sp_raise_nomethod(sp_nomethod_msg("left=", _t1)); break; }
```

Such a slot now keeps its arm and takes the value through `emit_obj_upcast_prefix`, as a store on a typed receiver does (`case 0: ((sp_Node *)_t1.v.p)->iv_left = (sp_Node *)_t2; break;` and the same for `Column`). The value form of the store goes through the same function and is fixed with it. An arm that calls a written `def x=` is as it was.

The slot and the value come out typed this way when the method that stores through the writer stands above `initialize`, which is how `tools/order_probe.rb` (#7099) came to it: `test/dlx_subclass_ring_attr.rb` with `initialize` and `link_right` of `Node` exchanged raised the NoMethodError. In file order `@left` is boxed and the store was right; that difference in precision between the two orders is not touched here. The emitted C of all 5,903 programs in `test/`, `test/reject/`, `test/infer/`, `benchmark/`, `examples/` and the packages' tests is byte-identical before and after (both compilers built on 0d370b71).

`test/boxed_writer_subclass_value.rb` stores through the writer as a statement and for its value, into a `Node` and into a `Column` receiver, and reads the links back. It prints its `.expected` plain and under `SPINEL_GC_STRESS=1`, and raises on master. The change is 19 lines in `src/codegen_stmt.c`: a helper, and three lines of `emit_boxed_writer_arms` (64 lines).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it prints seven Strings)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (OPTCARROT_LINE)
- [ ] Depends on: # (nothing; #7099 is the probe that found it and is merged)
