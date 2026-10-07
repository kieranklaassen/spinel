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

with gcc and with clang, for a method the program adds to Object, Kernel, String, Symbol, Integer, Float, Range, Array, Hash or Numeric. A class's own method runs `recv` first. Those arms write the receiver in place, one C argument beside the others, while `emit_args_filled` runs an argument that allocates ahead of the statement.

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

in a plain run of gcc's build: gcc makes the empty Array first and `Door.new` collects it. clang makes the Door first and the Array's allocation collects that: a `note` that reads the Door faults under `SPINEL_GC_STRESS=2`.

`emit_reopen_recv_in_order` opens such a call as a statement expression where it stands: the receiver bound to a rooted temp, then what the arguments hoist, then the call. It does so when the receiver and an argument (or a default the call leaves out) both have an effect, or when the receiver allocates and the method has a rest or leaves out a default that allocates. Every other call keeps master's C: `make cident` finds four corpus programs changed, each at a call that meets this test. A call it takes costs one temp and its root: 200,000 of the first program's calls go from 83,238,799 to 85,638,821 instructions under callgrind.

Not in this change: the receiver of a method added to TrueClass, FalseClass or NilClass.

`test/reopen_receiver_runs_first.rb` prints 13 lines and joins `GC_STRESS_TESTS`; master fails it with gcc and with clang, plain and under stress.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
