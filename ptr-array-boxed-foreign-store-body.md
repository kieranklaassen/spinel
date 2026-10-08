<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A value stored by `<<` or `[]=` into an Array whose elements were all one class came back as nil, or as an object of that class.

```ruby
class K
  attr_reader :n
  def initialize(n) = @n = n
end
class J
  def n = 9
end
t = [K.new(1)]
h = { a: "s", b: J.new }
t << h[:a]
p t[1]
t << h[:b]
p t[2].n
```

`spinel diff` on master:

```
spinel diff: output-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"s"
-9
+nil
+0
```

`t << Object.new; p t.last.class` prints K, and with a Float in the Hash `t[0] = h[:a]; p t[0].n` ends in a segmentation fault where CRuby raises NoMethodError.

**It has a cost, yours to weigh.** Such an Array now stays boxed unless every boxed value stored into it is proved an object of its class. A program that stored only objects of the class, through a value nothing here proves (a Hash's value, a method that answers one of two classes, an element of a boxed Array), was right on master and now runs on the boxed Array. Instructions a turn of the loop (callgrind), master and here; the last column is the same loop on master over the literal `[K.new(1), h[:a]]`, the Array this one becomes:

| the loop | gcc master | gcc here | clang master | clang here | the literal, gcc and clang |
|---|---|---|---|---|---|
| `s += t[i % 2].n` | 31 | 31 | 35 | 29 | 31 and 29 |
| `t << h[:a]` | 51 | 52.3 | 66 | 52.3 | 52.3 and 52.3 |
| `t.each { \|e\| s += e.n }`, two elements | 49 | 84 | 70 | 76 | 84 and 76 |

An Array whose elements are all one user class is a pointer array (`narrow_object_arrays`). A boxed value is no evidence against the class there, so that a method's widened return keeps the Array typed, and `<<`, `push` and `[]=` unbox it with `sp_poly_obj_ptr`: the pointer of any object, NULL for everything else. The comment speaks of a class check at run time; there is none.

The pass now notes the boxed values those stores put into a slot (`oa_store_evidence`) and, once the components have their classes, asks of each whether it is proved an object of the class or of one beneath it (`oa_value_class_proved`). One that is not is the foreign element a String stored by its type is: the Array stays boxed and holds it. A value is proved where the program says so without a run:

- a call of a method whose whole body is a read of one of its parameters, on a proved argument (the widened return the unboxing was written for);
- a call of a method that answers one class, on a proved receiver;
- a local every write of which is proved;
- an element of such an Array: an index read, `first`, `last`, `min`, `max`, and the parameter a walk of it hands its block (`o.each { |e| t << e }`).

Such a program compiles to the C it had.

**The other repair, not taken.** The class check the comment speaks of, raising TypeError at the store as an Array of a declared kind does, keeps the pointer array for every program in the table above. It also refuses the programs that store such a value and never read it as the class (`t << h[:a]; p t.size`), which are right on master, where CRuby stores the value. If you would rather have the check, it is a small change in the two store arms and I will send it instead.

Checked on master 548d4196def8, with gcc and clang:

- `test/ptr_array_boxed_foreign_store.rb` prints 14 of its 23 lines wrong on master and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`.
- 1,728 generated programs (12 kinds of value, through a widened method, an element of a literal and a mixed literal, into `<<`, `push` and `[]=`, on 3 Arrays, read 4 ways), each against CRuby: 736 compile to master's C; 552 go from wrong to right; 440 were right and stay right on the boxed Array. Of those 440, 248 store a value of another kind that the program only counts or asks for its class, and 192 store an object of the class, of a class beneath it or nil through an element of a literal. None that was right is lost.
- 266 more programs (a value out of a Hash, a local, a parameter, a block, an instance variable, another Array; a plain `Object.new`): 117 compile to master's C, 52 go from wrong to right, 96 were right and stay right on the boxed Array (the cost above) and 1 goes from a wrong answer to NoMethodError (the singleton method below). None that was right is lost.
- `tools/cident.sh` against 548d4196def8: 6484 identical, 0 refusal changes, and the new test the one that differs. `test/ptr_array_push_poly_value.rb`, `test/ptr_array_set_poly_value.rb` and `test/poly_dispatch_comparator_slot.rb`, which store a widened return, keep their C.
- The compiler runs as many instructions as before to within 0.02%: `kernel_conv_protocol` 739,144,192 on master and 739,216,960 here, `bundle_misc_b` 428,110,774 and 428,193,918, and 300 tables with boxed stores 1,755,098,671 and 1,755,395,881, all three the same C.

Left alone:

- `unshift`, `insert`, `fill`, `concat`, `+=`, `map!` and a literal box the Array on master already and are right there.
- A table of Integer rows or of Float rows given a boxed row is boxed on master already.
- An object with a singleton method (`def o.n`): its method is not found on master with no Array at all; stored into such an Array it printed 0 and now raises that NoMethodError.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
