<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that matches a Regexp in a `when` arm, or through `any?`, `all?`, `none?` or `one?`,
left its match, or the nil of a miss, in its caller's `$~`. The test that gives a matching
method its frame knew the matching calls and neither of these:

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

On master 5390d300 with the pull requests beneath: no program's C changes but this pull
request's own test (`make cident`). A method that matches this way now pays the frame: 844
instructions a call (callgrind, 200,000 calls) and 16 bytes of C stack for the frame's cleanup,
so a recursion through a `when` arm that ran 699,033 deep runs 599,171.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection), # (A matching method starts with no match; a jump out restores its caller's)
