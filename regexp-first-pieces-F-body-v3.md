<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A method that matches a Regexp in a `when` arm, or through `any?`, `all?`, `none?` or `one?`,
left its match, or the nil of a miss, in its caller's `$~`. The test that gives a matching
method its frame (#3629) knew the matching calls and neither of these:

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
its own (`match_frame_closed`, from the pull request this depends on). The test is put to the
frames such a program gets, so a method that matches only this way no longer fails it for
saving no frame. Every other program is emitted as before, byte for byte: a proc, a kept block
or a Fiber shares the one set of registers with the method that runs it, and a frame there
would take the block's match away (`test/regexp_when_frame_kept_block.rb`,
`test/regexp_when_frame_fiber.rb`).

On master dafa0d047: no corpus program's C changes (6,277 the same, 3 refused). Of 1,226
generated programs (a quantifier in a method, a closure run inside a matching method, a
matching body in a Fiber, a Thread or an Enumerator) 276 are made right and none is lost, with
`SPINEL_GC_STRESS` unset and 2. A method that matches this way now pays the frame a method
that matches with `=~` pays.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection), # (A method that matches starts with no match, and a jump out of it gives its caller's back)
