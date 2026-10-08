<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that yields, called with a block inside a proc, read and wrote the proc's captured variable wherever one of its own had the same name.

```ruby
def twice(n)
  yield n * 2
end
n = 10
g = -> { twice(3) { |v| v + n } }
p g.call
```

```
spinel diff: output-diff
  program: twice.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-16
+30
```

A write goes the same way, into the caller's variable:

```ruby
def twice(a)
  m = a * 2
  yield m
end
m = 10
g = -> { m += 1; twice(3) { |v| v + 1 } }
p g.call, m
```

```
spinel diff: output-diff
  program: keep.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
 7
-11
+6
```

The builtins written in Ruby are such methods, and their parameters have plain names (`max_by(n = nil)`, `min_by(n = nil)`, `each_with_object(memo)`):

```ruby
nums = [3, 1, 2]
n = 1
g = -> { n += 1; nums.max_by(1) { |v| -v } }
p g.call
```

```
spinel diff: output-diff
  program: maxby.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[1]
+[1, 2]
```

With `nums.max_by { |v| -v }` in that proc the C does not build (`builtins/enumerable.rb:148: error: incompatible type for argument 2 of 'sp___enum___no_false__3'`), called or not.

A method that yields is inlined where it is called with a block, its parameters and locals under names of their own (the rename map). In a proc's body a local the proc captures is read through the capture struct, and `emit_scope_local_ref` asked "is this name captured" of the bare name before it looked at the map: `twice`'s `n` was the proc's `n`.

`local_is_capture()` says no for a name the live inline renamed. The capture is out of scope until the inline ends: the block the method yields to is emitted with the map parked, and reads the capture again (`v + n` above). Seven sites asked the bare name and now ask it: the read and write of a local (`emit_scope_local_ref`), the two fills of the captures of a proc or a thread made inside the method, the two writes of a Proc-valued local's cell, the rebind of an aliased parameter, and the slot lent to an appender (`emit_lent_local`). The other places that spell a capture have no program that reaches them with a renamed name, and are as they were.

The two Proc cell writes also spelled a cell of the method by its bare name, so a Proc of an inlined method that calls itself did not build, with or without a proc around the call:

```ruby
def wrap(a)
  r = ->(k) { k <= 0 ? 0 : k + r.call(k - 1) }
  yield r.call(a)
end
p wrap(3) { |v| v + 1 }
```

```
spinel diff: link-error
  program: selfcall.rb
  ruby:    exit 0
  spinel:  the C did not build

selfcall.rb: In function '_sp_main_body':
selfcall.rb:2: error: '_cell_r' undeclared (first use in this function)
```

They take the renamed cell, which the first change needs: inside a proc the method now asks for its own cell there.

Measured with gcc and clang at `SPINEL_GC_STRESS` 0 to 2 over 8,064 programs: 21 methods (a parameter read or written, a local, `||=`, a multiple assignment, loop counters, an appended String, a lambda of the method, keyword and default parameters, a rescued exception's name, `for`, a method inlined in a method, two yielded values, and `max_by`, `min_by`, `each_with_object`), the captured variable an Integer, a String or an Array, written in the proc before the call or not, read by the block or not, the proc made by `->`, `proc`, `Proc.new`, `lambda`, returned from a method, made in a block, or a `Thread.new` body; each with a twin where the two names differ, and each with a twin whose proc is never called. 2,160 change their C, all with the names equal and the variable captured. Of the 1,080 that call the proc, 782 did not build on master and 292 answered wrong with exit 0; all are right here; 6 are right on both. The 1,080 never-called twins: 782 did not build on master and build and run here; 298 are right on both. No twin under another name changes, nor a block that is no proc, nor a `Thread.new` body at the top level (336 of those run, right on both).

`tools/cident.sh` against master: four programs of `test/` change beside the new test, each a method inlined in a proc whose parameter has the name of a variable the proc captures (`io_each_line_splat_args`, and a bare `super` in a proc whose parent names its parameter as the child does: `super_in_proc_forwards_block`, `super_inlined_parent_yield_value`, `zsuper_in_proc_captures_params`). They read the method's own local where they read the capture, which held the same value. All four answer as on master with gcc and clang at stress 0 to 2 (the two `*_in_proc_*` tests crash at stress 2 on master and here alike). optcarrot's C is the same.

Not here, the same on master: a parameter the method appends to and then rebinds (`u << "a"; u = +"new"; u << "b"; yield u`), called in a proc, aborts under `SPINEL_GC_STRESS=2` ("the mark reached a freed heap string") whatever the names are.

Test: `test/proc_inlined_method_own_local.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: nothing
