<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that matches through `slice!`, an index assignment that names a group, or a pattern
of `in` or `=>` left its match in its caller's `$~`. The test that gives a matching method its
frame knew none of the three.

**Cost.** A method that matches this way now pays the frame: 841 instructions a call and at
most 16 bytes of C stack. The two recursions measured lose none (599,128 deep through `slice!`
and 524,273 through `in`, before and after); a method whose compiled frame has no room for the
cleanup loses the 16 bytes, as a `when` arm does in the pull request beneath (699,031 deep to
599,170). CRuby 3.3 stops these recursions near 8,189 with SystemStackError.

```ruby
def cut(s) = s.slice!(/(b)/)

def kind(s)
  case s
  in /a(b)/ then :ab
  else :other
  end
end

"q1" =~ /q(\d)/
cut(+"abc")
p $1
"q1" =~ /q(\d)/
kind("ab")
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
+"b"
+"b"
```

`scope_performs_match` now counts them, in a program where a method's registers are provably
its own (`match_frame_closed`, from the pull requests beneath). A pattern is searched whole:
the Regexp may sit in an array, a hash or an alternative, or behind a pin or a constant.
`s[re] = v` sets no register and is not counted. Every other program is emitted as before,
byte for byte: a frame there would take away the match of a block the method runs
(`test/regexp_frame_slice_kept_block.rb`).

On master b4d30a1d with the pull requests beneath: beside the test the C of one program of the
corpus changes, `test/string_splice_family.rb`, by the frame line of three methods (`make
cident`). The instructions are callgrind's over 200,000 calls, the depths the deepest run on an
8 MB stack; the 16 bytes are the frame's cleanup, which holds the method's return value across
the call that puts the registers back.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection), # (A matching method starts with no match; a jump out restores its caller's), # (A method matching in a `when` arm or a quantifier keeps its caller's $~), # (any?, all?, none? and one? given a Regexp stop where CRuby stops), # (A method that matches a String pattern keeps its caller's match), # (String#match and Regexp#match leave $~ at their match)
