<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A method that matches saves its caller's `$~` on the way in and puts it back on the way out
(#3629). The saved Strings were held by that frame alone, and unrooted, so a collection while
the method ran freed them and the caller read another String's bytes:

```ruby
def hit?(s) = (s =~ /rr/) ? 1 : 0
"k9" =~ /k(\d)/
n = 0
i = 0
words = ["apple", "berry", "cherry", "avocado"]
while i < 200_000
  n += hit?(words[i & 3])
  i += 1
end
p n, $1     # 100000 and "rr"; CRuby prints 100000 and "9"
```

No stress variable is needed for that. Under `SPINEL_GC_STRESS=2` the mark reports a freed heap
string in phase `globals:regex`.

`sp_re_frame_push` now roots each saved String that is set, on the ordinary root stack, and
`sp_re_frame_pop` drops those roots as it puts the Strings back. A raise that leaves the method
runs no pop; the frame's roots go where the landing resets the root stack, as every other root
does.

Measured on master c2dadf497; a number taken on an earlier master says which. lib/sp_re.c and
lib/sp_re.h, the two files this changes, are the same bytes on every master named here.

- `test/regexp_frame_caller_match_gc.rb` is right with `SPINEL_GC_STRESS` unset, 1 and 2 (gcc
  13.3; with clang 18.1 on 2bd029b7e). On master 10 of its 16 lines differ in a plain run.
- The generated C of the corpus (6,126 programs) is byte-identical; the change is in lib/.
- 120 corpus programs save a frame, 119 of them with an expected output. Plain and at level 1
  each answers as on master. At level 2 the nine of packages/net are left out of the count:
  they start a server thread and most answer differently from one run to the next (two are
  right on both every time). Of the other 110, 14 fail at level 2 on master and 7 of those
  are right with this:
  test/gsub_block_regexp_value.rb, match_frame_pre_post_restore.rb,
  match_globals_frame_local.rb, nmatch_sets_last_match.rb, regex_posix_class.rb,
  regex_value_as_match_arg.rb and strict_arg_conversion.rb. The other 7 fail as before, from
  other causes.
- 2,387 programs of a matrix of Regexp readers, each built and run on both (on 2bd029b7e):
  every one answers as on master (931 right on both). Two programs that suspend a Fiber
  inside a matching method and collect before resuming are wrong on master and right with
  this at all three levels.
- A program that raises through two matching methods, collects in the rescue and matches again is
  right at all three levels with both compilers.
- Cost: a call of a matching method whose caller has a match set pushes and pops up to fourteen
  roots, 139 instructions (callgrind, the loop above: 244.7M to 272.5M for 200,000 calls). A
  caller with no match set pays 110 a call (244.7M to 266.7M for the loop without its first
  line): the fourteen tests and the count, no root. The root depth is put back by the pop
  itself: the cost a call is the same over 100,000 and over 1,000,000 calls. On 2bd029b7e: a
  matching method 100,000 calls deep costs 2% more in a plain run (410.5M to 419.5M) and is
  right at level 1; at level 2 every collection walks every frame, so that depth did not
  finish in 15 minutes (master stops on the collector's check there), and 10,000 deep it is
  right in 11 s.

Left alone: after a raise through a matching method the caller's `$~` is the method's, since
the pop does not run (`def boom(s) s =~ /z(.)/; raise ArgumentError end`, rescued, then `p $1`
prints the method's capture; CRuby prints the caller's). That is so on master too.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
