<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An index assignment by a Regexp is a match: CRuby leaves `$~` at what it replaced, and at nil
before the IndexError where nothing matched. Here the assignment searched with registers of its
own, so `$~` stayed at the match before it, or at the caller's.

**Cost.** The assignment pays 219 instructions more for leaving the match, and a method whose
only match it is now pays the frame as well: 1,058 a call in all. The recursion measured
through such a method loses no depth (599,128 before, 599,129 after).

```ruby
s = +"hello world"
s[/o (w)/] = "0 W"
p s, $~[0], $1

def swap(t)
  t[/(\d+)-(\d+)/] = "x"
  [$1, $2]
end

"k9" =~ /k(\d)/
p swap(+"a 12-34 b")
p $1
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,5 +1,5 @@
 "hell0 World"
-"o w"
-"w"
-["12", "34"]
+nil
+nil
+["9", nil]
 "9"
```

The two-argument arm now matches as `sp_re_match` does and then splices
(`sp_str_splice_re_last`). The frozen test stays ahead of it, and the value is still read
before the match, so `s[/(\d)/] = $1` reads the match before.

**Chosen: in a program where a method's registers are provably its own**
(`match_frame_closed`, from the pull requests beneath). The method must keep its caller's `$~`
once it matches, so `scope_performs_match` counts the assignment where its receiver is a
String, and only where the method then has a frame does the arm leave the match. Every other
program is emitted as before, byte for byte (`test/string_regexp_assign_kept_proc.rb`), and so
is an assignment inside the block of a `gsub` or a `scan`, which puts its own match back.

**Rejected.** Leaving the match in every program: a method with no frame would leave it in its
caller's `$~`, which is right today.

On master b4d30a1d with the pull requests beneath: no program's C changes but this pull
request's own test (`make cident`). The instructions are callgrind's over 200,000 calls, the
depth the deepest run on an 8 MB stack.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection), # (A matching method starts with no match; a jump out restores its caller's), # (A method matching in a `when` arm or a quantifier keeps its caller's $~), # (any?, all?, none? and one? given a Regexp stop where CRuby stops), # (A method that matches a String pattern keeps its caller's match), # (String#match and Regexp#match leave $~ at their match), # (A method matching by slice!, `s[re, n] = v` or `in` keeps its caller's $~), # (String#[]= with a Regexp group keeps its pieces rooted), # (String#[]= with a Regexp group raises for a missing group or nil)
