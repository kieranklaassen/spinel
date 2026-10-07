<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`$~` belongs to the method that matched. A method that matches saves its caller's registers in
a frame, but the frame started with the caller's match still in them, and a jump out of the
method (a raise, a throw, a break, a proc's return) put nothing back, so the caller read its
callee's match:

```ruby
def first(s)
  was = $1
  s =~ /a(.)/
  was
end

def boom(s)
  s =~ /z(.)/
  raise ArgumentError, "x"
end

"k9" =~ /k(\d)/
p first("ab")
begin
  boom("zq")
rescue ArgumentError
end
p $1
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-nil
 "9"
+"q"
```

The frame now starts empty, and a jump pops the frames of the methods it leaves. A frame
entered this way is kept beside the C stack, where the collector marks the Strings it saved,
so a matching method's C frame is smaller by the 400 bytes of the frame and a recursion runs
deeper than it did (1,572,819 on the main stack where it ran 149,789).

**Chosen: only in a program where a method's registers are provably its own**
(`match_frame_closed`). There is one set of registers, and code of another frame shares them
with the method that runs it: a block that may run as a Proc or a Fiber body; a method that
takes a block, or that saves no frame; a class or module body, a `class << self` body and a
required file's top level, which run in the top level's frame here; an `END` body; a method's
parameter defaults, which the caller evaluates. Where such code reads or may set the
registers, popping a frame would take its match away
(`test/regexp_frame_jump_kept_block.rb`), so that program is emitted as before, byte for
byte, as is one that runs a Fiber, an Enumerator or a Thread. After emission each block the
emitter made a Proc or a Fiber body, and each `END` body, is held against the test's list,
and one it did not count stops the compile rather than answer wrongly.

**Rejected.** Popping on every jump: the kept-block program, right today, would lose its
match. Deciding method by method: a block reaches a method through an ivar, a constant, a Hash
or `define_method`, and no list of routes closes.

On master 5390d300 with the pull request beneath: twelve programs change their C, by the frame
line alone, this pull request's two tests among them (`make cident`). A call of a matching
method costs 95 instructions less (the saved Strings are marked, not rooted), a raise out of
one 347 more (the pop that did not run), a raise or a throw in a program with no Regexp 3 more
(callgrind, 200,000 calls).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection)
