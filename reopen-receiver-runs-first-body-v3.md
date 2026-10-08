<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class String
  def pair(a) = "#{size} #{a.size}"
end

def recv
  puts "recv"
  "s" + ARGV.size.to_s
end

def arg
  puts "arg"
  [1, "a"]
end

puts recv.pair(arg)
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-recv
 arg
+recv
 2 2
```

with gcc and with clang, for a method the program adds to Object, Kernel, String, Symbol, Float, Range, Array, Hash or Numeric, and to Integer where the method has a rest or a keyword. A class's own method runs `recv` first. Those arms write the receiver in place, one C argument beside the others, while `emit_args_filled` runs an argument that allocates ahead of the statement. An argument that only reads is read too early the same way, in those arms and for an Integer's method with one positional parameter (below): with `$g = "g0"` and `def setg = ($g = "g1"; "r")`, `puts setg.pair($g)` against `def pair(a) = "#{self}|#{a}"` prints `r|g0` for `r|g1`.

Cost: a call this change takes holds its receiver in a rooted temp. Callgrind, instructions a call with gcc and with clang, over 200,000 calls of `def one(i) = mk(i).pair(cnt(i))` against `def pair(a, b = 1)`, where `cnt` counts in a global: a String receiver 18 and 15, an Array 10 and 9, a Hash 5 and 9, Numeric's method on an Integer 3 and 4, a Symbol 2 and 0; an Integer, a Float, a Range and an object 0. With an argument that reads a global, `mk(i).pair($n)`, which master ran right wherever `mk` does not assign it: String 21 and 14, Array 7 and 15, Hash 3 and 11, Numeric 4 and 4, the others 0. Object's method pays where that global is a String: `mk(i).pair($g)` against Object's `def pair(a, b = 1)` costs 9 and 13 on a String receiver (14 and 11 with `"#{$g}!"` for the argument) and 7 and 12 on an object passed by value. Up to about 20 instructions a call in all. Compile time: `spinel -c` over 2,000 such calls runs 1.4% more instructions. No other call's C changes.

The same placement loses an object. A rest or a default that the call makes in place stands beside that receiver with no root:

```ruby
class Object
  def note(m, *r) = "#{m} #{r.size}"
end

class Door
  def initialize
    @parts = []
    20000.times { |i| @parts << [i, "p", nil] }
  end
end

m = [:open, :shut][ARGV.size]
puts Door.new.note(m)
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-open 0
+open 3
```

in a plain run of gcc's build: gcc makes the empty Array first and `Door.new` collects it. clang makes the Door first, and the Array's allocation can collect that: with a small Door (`def initialize = @name = "door"`, `def label = @name`) and a `note` that reads it through the Door's `label`, clang's build faults under `SPINEL_GC_STRESS=2`.

`emit_reopen_recv_in_order` opens such a call as a statement expression where it stands: the receiver bound to a rooted temp, then what the arguments hoist, then the call. It does so when the receiver has an effect and an argument (or a default the call leaves out) has one too, when the receiver can change what such an argument reads (`read_rebound_by`, the question an argument list already asks of a read and a later argument), or when the receiver allocates and the method has a rest or leaves out a default that allocates. An Array, a Hash or an object the arm boxes is held as the pointer it is and boxed where the call takes it, so its root is a push and a pop, not a slot of a frame; a String, or an object passed by value, that Object's method takes is held boxed, in a frame slot. Every other call keeps master's C: `make cident` finds four corpus programs changed, each at a call that meets this test.

Not in this change, each with master's C and master's answer here: the receiver of a method added to TrueClass, FalseClass or NilClass, or to an exception class (`sete.pair($g)` against `class StandardError`). An Integer receiver whose method has one positional parameter, beside an argument that only reads: `seti.pair($g)` prints `4|g0` for `4|g1` (an argument with an effect runs in order there). In Object's, Kernel's and Numeric's arm, a keyword with an effect beside an interpolation that reads (`setg.pk("#{$g}!", k: seven)`). An argument that reads what the receiver changes in place and does not assign: a local's object (`psh(x).pair("#{x}")` where `psh` appends to `x`; `(b << "1").pair(b)` with gcc), or `$1` after the receiver's own match (`s[/b(c)/].pair($1)`). And a fresh String that is the receiver of a reopened String's method is not held across that method's allocations: `class String; def me = self; def c = (h = {}; h["k"] = 1; x = me; y = [1]; x.size + y.size); end`, `puts ("ab" + ARGV.size.to_s).c` aborts under `SPINEL_GC_STRESS=2` on master (the mark reaches a freed String). Where `c` ends in `me.pair(arg)` and `pair` never reads the String, master did not look at it and ran; the call is taken now, the String held, and that program aborts at stress level 2 as the first does.

`test/reopen_receiver_runs_first.rb` prints 16 lines and joins `GC_STRESS_TESTS`; master fails it with gcc and with clang, plain and under stress.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
