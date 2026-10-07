<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`$~` belongs to the method that matched. A method that matches saves its caller's registers in
a frame (#3629), but the frame started with the caller's match still in them, and a jump out of
the method (a raise, a throw, a break, a proc's return) ran no cleanup, so the caller read its
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

The frame now starts empty, and each jump pops the frames of the methods it leaves before it
jumps. The frames are chained, and a frame notes the depth of the exception, catch and break
stacks at its entry, which is how `sp_handler_stacks_unwind` already tells what a landing
leaves; no `begin`, `catch` or break arm records anything.

**Chosen: only in a program where a method's registers are provably its own.** There is one set
of registers, so a proc, a kept block or a Fiber shares them with the method that runs it, and
popping a frame there takes that block's match away:

```ruby
def calls(s, pr)
  s =~ /a/
  pr.call
  raise ArgumentError, "x"
end
pr = proc { "k9" =~ /k(\d)/ }
begin
  calls("a", pr)
rescue ArgumentError
end
p $1     # "9" in CRuby and today; nil if the frame were popped
```

`match_frame_closed` passes a program that reads the registers, holds no Fiber, Enumerator or
Thread, and in which none of these reads them or may set them: a block that may run as a
function of its own (every block and lambda but one given to a built-in value's own method, to
`loop` or to `catch`), a method that takes a block, a method that saves no frame, a class or
module body. There every read sees its own frame's match, which is CRuby's rule. Every other
program is emitted as before, byte for byte, and answers as before.

**Rejected.** Popping on every jump: the program above. Deciding method by method: a block
reaches a method through an ivar, a constant, a Hash, `define_method` or a helper, and no list
of routes closes. Either half alone: a frame that starts empty and is not put back by a raise
hands the caller no match; one put back and not emptied shows the next method a match the
leftover had hidden. One jump alone: a frame a throw left on the chain is read by the next
raise out of a C frame that has returned.

On master dafa0d047:

- Of the corpus's 6,280 programs 3 are refused, 9 change, by the line that opens the frame
  (21 lines), and 6,268 generate the same C. The 126 that save a frame answer as before with
  `SPINEL_GC_STRESS` unset, 1 and 2.
- An instrumented build counted the blocks emitted as functions of their own: 5,516 in the
  corpus, none outside the list above in a program that passes.
- 1,226 generated programs (a quantifier in a method, a closure run inside a matching method,
  a matching body in a Fiber, a Thread or an Enumerator): each answers as on master, with
  `SPINEL_GC_STRESS` unset and 2.
- Cost: a call of a matching method 30 instructions more (274.0M to 279.9M for 200,000 calls),
  a raise out of one 470 more (the pop that did not run), a raise or a throw in a program
  with no Regexp 3 and 5 (callgrind).

Left alone: the programs that fail the test, among them every program with a block that
matches inside a user method's iteration.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection)
