<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def pick(i) = i == 0 ? "pa".dup : nil
z = [pick(0), pick(1)]
z[0] << "!"
p z
```

dies with a segmentation fault (`spinel diff`: crash). CRuby prints `["pa!", nil]`. Without the `p z`, `z[1].nil?` answers `false`, `z.compact` keeps the element, and `z.each { |e| e << "?" if e }` raises NoMethodError. The same with `--share-strings`.

An element that is changed in place is stored as a String handle, and a value that is not a handle yet is wrapped in a fresh one where it is stored (the last arm of `emit_boxed_strbuf`). `sp_String_new_shared` hands a nil back as NULL, as its comment says, and the arm boxed that NULL with `sp_box_obj`: a String handle around nothing, which no reader takes for nil.

The arm now tests the value before it wraps it, and boxes a nil as nil. The other arms of the function and `emit_str_array_handles` make that test after the wrap, with `sp_box_nullable_obj`; made before it, the C compiler drops the test `sp_String_new_shared` makes itself. A String literal and an interpolated String cannot be nil (`node_may_be_null_nil`) and keep the C they had.

That is every value the arm takes, not only a method's: a slice past the end, an element or a Hash value that is not there, `find`, `&.`, a bang method that changed nothing, `gets` at the end of its input, a call found at run time; and every store that asks for a handle: an Array or a Hash literal, `<<`, `push`, `[]=`, a block's value in `map` or `Array.new`.

Cost on a program master ran right: a store of a value that can be nil tests it. In instructions a turn against master, gcc 13.3 / clang 18.1, callgrind over 300,000 turns of 1,400 to 3,100 instructions each:

| a turn | gcc / clang |
|---|---|
| `z = [mk(i), mk(i + 1)]`, a method's String twice | 0 / +4 |
| `h[:a] = mk(i); h[:b] = mk(i + 1)` | 0 / +4 |
| `z = [s.upcase, s.downcase]` | +7 / +10 |
| `w = [z[0].dup, "e#{i & 7}"]` | +6 / +3 |
| `z << mk(i)` | 0 / 0 |

`make cident` against master: the C of 6455 programs is identical and of 85 differs, the test and 84 that store such a value (80 tests, 3 package tests and the benchmark `bm_csv_build`); each of the 85 prints its `.expected` with gcc and clang, and the benchmark runs 14.08 billion instructions before and after (17,941 fewer with gcc, the same count with clang). optcarrot's C is unchanged.

Of 687 programs (12 ways to come by a nil, 10 stores, the reads) 155 are right on master, 246 crash, 50 raise and 236 print a wrong line; 647 are right here. The 40 left print what master prints: the element is written as a `||` or a ternary (`pick(1) || "o".dup`, `c ? "t".dup : nil`), and the append to it is lost.

The pull request "A String an object's method builds can be appended to where it is stored" rewrites the same statement for a call on an object. Whichever of the two goes second is replayed above the first; the two conditions join with `||`.

With `--share-strings` master refuses one store of the test, a call found at run time (`v = [n[0].plus, n[1].plus]`), before and after this; the test is not in `SHARE_TESTS`, and the rest of it is right under the flag.

Not here: a program that died at this store now runs on, so a wrong line master already prints further down shows. `src = ["xy".dup]; u = [src[0], pick(1)]; u[0] << "!"; p u, src` prints `["xy"]` for `src`, as master does today for `u = [src[0]]` with no nil in the program: an element read out of one Array and stored in another is a copy there (not with `--share-strings`). This does not touch it.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here before that, on this commit over master `16bca08960d1` (Linux x86-64, gcc 13.3 and clang 18.1, CRuby 3.3.6): the build from nothing, the test at five collector settings with both compilers (with `--share-strings` too, less its five lines of a call found at run time, which master refuses under the flag), `tools/gate.rb check`, `make share-strings-test` and `make cident`; and on the same change over `9c7ea3ce06f3`, where the C of the 687 programs and of optcarrot is the same, `make test OPT=-O1` (6421 pass, 1 fail: `socket_ipv6_and_class_methods`, which fails the same way on master here, the machine has no IPv6), `make bench` (67 pass), `make optcarrot` (checksum 59662) and `tools/refusals.sh`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: nothing
