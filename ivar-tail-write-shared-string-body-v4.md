<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method whose last statement stores a String it built in place answered nil.

```ruby
class Page
  def text
    return @text if @text
    b = +""
    b << "x" << "y"
    @text = b
  end
end
c = Page.new
p c.text, c.text
```

```
spinel diff: output-diff
  program: page.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"xy"
+nil
 "xy"
```

A tail instance variable write hands back the slot when the slot's type is the return's (`emit_stmt_tail_inner`). A String appended to in place under a second name lives in a shared-handle slot, which a String return cannot take as it stands, so the write went out as a statement and the method fell to `return NULL`. Such a write now goes out in its value form, the write and then the slot's ordinary read: the C `(@text = b)` and `return @text = b` already produce.

**The choice.** That read is a copy of the String, and a setter called as a statement would throw it away. The value form for every such write was built first and rejected: `def take(x); @s = x; end` called 20,000 times as a statement with a 1,000-byte String went from 1.5 to 10.0 million instructions (on 9c4eec71). So the value form is used only where the method's value can be seen to be wanted, and every other method keeps master's C byte for byte. One walk of the program, made by the first such write, lists each use of a method's name:

- wanted: a call that is no plain statement; a call that ends a method whose own value is wanted (followed three methods deep); the name as a Symbol or a String anywhere (`send(:set)`, `method(:set)`, `alias`, `&:set`); `super` in a method of that name; an op-assign through it; a name made at run time anywhere in the program (`send(n)`, `to_sym`); a name the runtime calls by itself (`to_s`, `inspect`, `message`, operators); a method no call names.
- dropped: a statement that is not the last of its sequence; the last statement of the program, of a loop, of an `if` that is itself such a statement, of a method whose own calls are all such statements; an attribute assignment, which is worth its right side.
- never: a method one of whose calls is stored straight into a container whose elements are changed in place (`h = { k: c.set("b") }` beside `h[:k] << "!"`, `a << c.set("b")`, `h[:k] = c.set("b")`). The caller types that call as the handle itself and boxes the answer unwrapped, so a String there is read as a handle: the `(@v = x)` twin segfaults on master today. Such a method keeps master's C, and the caller master's NoMethodError on nil.

Whatever the walk does not read as dropped is wanted, so a miss costs the copy and no answer. A use it cannot see at all would keep master's nil; I found none that runs on master (`eval` of a String is refused).

**Measured against CRuby 3.3.6 on master 8684d54c.** 786 generated programs whose method ends in `@v = ...`, each with a twin ending in `(@v = ...)`; the C of 262 changes, in the one line of the write.

| of the 786 | master | this branch |
|---|---|---|
| as CRuby | 472 | 692 |
| wrong and silent | 228 | 66 |
| raises where CRuby does not | 58 | 0 |
| the C does not build | 28 | 28 |

182 wrong and 38 raising become right; none right on master changes its answer. 100 more programs, one per route above: of the 58 that take the value, 52 were wrong or raising and are right, four were right already, and two are master's on both (`c.text ||= "z"` does not build, a call answered by `method_missing` raises); the 18 that drop it and the 13 that store it as a handle are master's C. The setter loop above is master's C and master's instruction count; a program of 4,000 such methods compiles in the time master takes.

**Limits.** 20 of the 786 raised on master and print one wrong line here. The plainest of them, whole (an instance method, the value built with `<<`, no other method appending to the variable):

```ruby
class C
  attr_reader :v
  def set(n)
    x = +"a"
    x << n
    @v = x
  end
end
c = C.new
r = c.set(+"b")
r << "!"
p r                     # CRuby "ab!"; here "ab!"; master: FrozenError at `r << "!"`, r being nil
p c.v                   # CRuby "ab!"; here "ab"
```

The other nineteen end in the same four lines: thirteen with the method somewhere else (a class method, the top level, a module, a subclass, under `begin`, `rescue`, `ensure`, an `if` arm, a guard return, through `send`, behind a second method) and six with the value come another way (a second name, a conditional, a value that may be nil, a second method appending). The same holds for every in-place change of the answer (`insert`, `replace`, `clear`, `concat`, `prepend`, `upcase!`, an index assignment, a method that appends to its argument): the change lands in the copy. One of them, `r.insert(0, "Z")`, also stops in the collector under `SPINEL_GC_STRESS=2`, as its twin does on master. The twin of the program shown, the same program with `(@v = x)` as the method's last statement, prints "ab!" and "ab" on master: a method's String return of a shared String is a copy for every tail on master (`@v = x; @v`, `return @v = x`, `@v = x; x` print the same). The right answer needs the method to hand back the handle itself, which is sharing and not in this piece; CONTRIBUTING asks for no new sharing rule, and a refusal here alone would refuse programs whose twin builds. For each changed program that builds, the output here is byte for byte the output of its twin on master.

Not touched: `y = x` as a method's last statement and a block's body ending in the write do not build on master, and still do not.

**Generated C.** `make cident REF=8684d54c`: `6341 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The one is the new test. `tools/refusals.sh` passes. Under `--share-strings` the C of none of these programs changes: there the flag's own arm for a tail write answers first. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/ivar_tail_write_shared_string.rb`: 12 of its 18 lines are wrong on master. Its last case is a method nobody asks, which keeps storing. It prints the same under `SPINEL_GC_STRESS=1` and `2`, built with clang, and under `--share-strings`. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test prints Strings and one Integer.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
