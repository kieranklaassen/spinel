<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class K
  def initialize(x) = @x = x
  def plus = @x + "a"
end
class L < K
  def plus = @x + "b"
end
class Q                      # nothing makes one
  def initialize(x) = @x = x
  def plus = @x + "a"
end
b = [K.new("p".dup), L.new("q".dup)]
z = [b[0].plus, b[1].plus]
z.each { |e| e << "!" }
p z                          # ["pa!", "qb!"]
```

printed `["pa", "qb"]`, with no error. Without class Q it was right. The same with `z[0] << "!"`, `upcase!`, a Hash literal and `z << b[0].plus`, and with a class in `b` whose `plus` answers an Integer. `z[0].concat("+")` raised `undefined method 'concat' for an instance of String` there: the same value box, which `concat` cannot turn into a handle.

An element that is changed in place is stored as a String handle, and a call that answers a String is wrapped as a fresh handle where it is stored. `b[0].plus` finds its method by the class of the element. With Q's untyped `plus` among the methods of that name, or beside a class whose `plus` answers an Integer, the call's answer is boxed: each class's arm boxes its `const char *` as a value (`sp_box_str`), the store keeps that box, and `e << "!"` on a value box answers a new String the element never takes.

The arm of a class whose method builds its String now answers the fresh handle a typed call's store makes, where the store's handle demand has marked the call. `strbuf_demand_store_leaf` marks it where the call still reads as a String there; `strbuf_demand_value_leaves` now marks a call on a boxed receiver that reads as boxed. One helper, `poly_arm_fresh_handle`, serves the arm without arguments and the two with.

Only an arm whose method is seen to build its String takes it (`method_builds_string`, the test the pull request this depends on uses for a call on an object of a known class): an interpolated String, `to_s`, `inspect` or `chr` of an Integer or a Float, or a String method that always answers a new String. Every other arm boxes as before, so no String gets a second handle:

- a method that answers a String something holds (`def held = @x`), a reader, a native class's method, a builtin value's arm;
- a call that no store with a handle demand marked: the dispatch in any other place is master's C.

Measured on 64450fba3305 above the pull request this depends on, over 1,134 programs (nine sets of classes, seven ways to store, nine changes, two sets of reads): 450 that printed a wrong line or stopped print CRuby's output, 414 that were right stay right, 242 keep the fault they had and 28 are refused before and after. None that was right is lost, and none that stopped prints a wrong line.

Not in this change:

- A dispatched call kept in a local first (`t = b[0].plus; z = [t]`) still loses the change.
- A method that answers the String it holds, stored and changed the same way, still loses it at the object: `g = [b[0].held]; g[0] << "!"` leaves `b[0].held` unchanged.
- A nil among the answers, where every other class of the name answers a String: with `class N; def plus = nil; end` beside K alone, `v = [n[0].plus, n[1].plus]; v[0] << "!"; p v` stops with a segmentation fault, as on master. The stored nil is wrapped as a String handle; `def pick(i) = i == 0 ? "pa".dup : nil` and `z = [pick(0), pick(1)]` do the same with no class at all.

`tools/cident.sh` against the commit below, on 3ab4539fcc9f: 6508 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "A String an object's method builds can be appended to where it is stored"
