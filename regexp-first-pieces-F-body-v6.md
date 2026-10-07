<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that matches a Regexp in a `when` arm, or through `any?`, `all?`, `none?` or `one?`,
left its match, or the nil of a miss, in its caller's `$~`. The test that gives a matching
method its frame knew the matching calls and neither of these.

**Cost.** A method that matches this way now pays the frame: 843 instructions a call and 16
bytes of C stack, so a recursion through a `when` arm that ran 699,031 deep runs 599,170. Only
a program that recurses deeper than that through such a method is lost; CRuby 3.3 stops the
same recursion at 8,189 with SystemStackError.

```ruby
def kind(v)
  case v
  when /a/ then :a
  else :other
  end
end

def any_b(a) = a.any?(/b/)

"q1" =~ /q(\d)/
kind("zz")
p $1
"q1" =~ /q(\d)/
any_b(["zz"])
p $1
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"1"
-"1"
+nil
+nil
```

`scope_performs_match` now counts both, in a program where a method's registers are provably
its own (`match_frame_closed`, from the pull request beneath). Every other program is emitted
as before, byte for byte: a proc, a kept block or a Fiber shares the one set of registers with
the method that runs it, and a frame there would take its match away
(`test/regexp_when_frame_kept_block.rb`, `test/regexp_when_frame_fiber.rb`), and so does an
`END` body (`test/regexp_when_frame_end_block.rb`).

On master b4d30a1d with the pull requests beneath: no program's C changes but this pull
request's own test (`make cident`). The instructions are callgrind's over 200,000 calls, the
depths the deepest run on an 8 MB stack; the 16 bytes are the frame's cleanup, which holds the
method's return value across the call that puts the registers back.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection), # (A matching method starts with no match; a jump out restores its caller's)
