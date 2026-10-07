<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that yields has no function here: its body is spliced where it is called, and its
block where it yields. So a method that matches and yields shared one `$~` with its block and
its caller: the block read the method's match, the method went on with the block's, and the
caller was left with the last of either. A tokenizer that reads `$'` after its yield stopped
after one token when the block matched.

**Cost.** A call of such a method now pays the frame, 841 instructions, and a yield to a block
that touches `$~` pays 1,637 more for the exchange; a block that touches no match pays nothing
at the yield. The method that writes the call keeps 16 bytes of C stack for it, so a recursion
through such a call that ran 1,198,339 deep runs 1,118,451; only a program that recurses deeper
than that is lost, and CRuby 3.3 stops the same recursion at 3,639 with SystemStackError. A
method that yields and does not match pays nothing.

```ruby
def each_b(s)
  s =~ /(b+)/
  yield $1
  $1
end

"k9" =~ /k(\d)/
p each_b("abbc") { |w| p [w, $1]; w =~ /(.)\z/ }
p $1
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-["bb", "9"]
-"bb"
+["bb", "bb"]
+"b"
 "b"
```

The splice now opens the method's frame in the scope of its body, so every way out of the body
puts the caller's registers back. Around a block the method yields to, the registers are
exchanged with the ones that frame saved: the block runs with its writer's match and leaves it
its own, and the method goes on with the match it had. The exchange is noted like a frame, so a
jump out of the block undoes it on its way.

**Chosen: in a program where a method's registers are provably its own**
(`match_frame_closed`, from the pull requests beneath), which until now any method taking a
block put outside. A method that takes its block only by yielding counts as a frame of its own
where it matches, and a block given to a name every method of which is spliced so runs where it
is written. Still outside, and emitted as before, byte for byte: a method that names its block
as a parameter (`test/regexp_frame_yield_kept_block_param.rb`), a constructor, a method of a
name that calls `super`, a name that is also a reader, and a method that yields from a block
which may run as a function. After emission a block that became a function and yields for a
spliced frame stops the compile rather than answer wrongly.

**Rejected.** Saving the method's registers in a C local around the yield: a raise out of the
block would leave the method with the block's match where it rescues, and the block's writer
without it where the writer does. Giving the block a frame of its own: its match is its
writer's, who reads it after the call.

On master b4d30a1d with the pull requests beneath: beside the tests, the C of four programs of
the corpus changes (`make cident`), each now inside the test, and each prints what it printed
at GC stress unset, 1 and 2. The instructions are callgrind's over 200,000 calls, the depths
the deepest run on an 8 MB stack.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection), # (A matching method starts with no match; a jump out restores its caller's), # (A method matching in a `when` arm or a quantifier keeps its caller's $~), # (any?, all?, none? and one? given a Regexp stop where CRuby stops), # (A method that matches a String pattern keeps its caller's match), # (String#match and Regexp#match leave $~ at their match), # (A method matching by slice!, `s[re, n] = v` or `in` keeps its caller's $~)
