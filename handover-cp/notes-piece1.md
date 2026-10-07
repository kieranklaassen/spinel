### Piece 1: `odd?`, `even?`, `~` and `chr` with an encoding on a boxed value that is no Integer

Class: fix (silent wrong answers). One commit on matz master 5390d3002886 (the tip at 05:52 UTC 10-07): 1439e838f92557a5db4d4fefd25916aa2390023a, tree 30cb5a5c3cde118969dec0941af30e1f0385df9f; The commit is in the fork: this branch's head has it as a parent through a merge that keeps the tree (`git merge -s ours`), so a fetch of this branch brings it and a new branch can be cut at it. `handover-cp/boxed-integer-only.patch` in the hand-over commit is its `git format-patch -1 --no-signature`; `git am --committer-date-is-author-date` of it on 5390d300 gives the same commit. This branch's tree is that commit's tree. It touches no nil helper. `lib/spinel_rt.h` is added to (`sp_poly_recv_integer_i`, `sp_poly_chr_enc_raise`, `sp_poly_even_p`, `sp_poly_odd_p`); no helper master has is changed.

Third form. Against the second form (fd2c3866), by the second reading:

- An inherited definition no longer takes the Integer's answer. Where the program defines `odd?` or `even?` in Integer, Numeric, Comparable, Object, Kernel or BasicObject (a module included or prepended in one is copied into it), at the top level, or by an `alias`, the call is master's C byte for byte (`parity_def_above_integer` in `src/codegen_call_operator.c`). The reader's F1, F2 and F3 are right under gcc and clang; a definition in any other class takes the new dispatch.
- `chr` with an encoding raises behind one test of the tag, where the second form's three-way expression cost 17 instructions a call under gcc.
- `sp_poly_even_p` and `sp_poly_odd_p` mark the Integer tag as the likely one; no cell costs more than master.

Master moved three times while this form was measured (26d456ec at 04:45, 9653e3e7 at 05:36, 5390d300 at 05:52). How the rows stand on 5390d300:

- A row is a measured row. It is carried from the master it was measured on to a later one only where the same compiler source emits the same C for the program, byte for byte, on both, and that C calls no runtime function that changed between them; every other program is run again (`handover-cp/carry.rb`; `run2.rb` runs a program, `tab.rb` makes the tables). From 8684d54c to 26d456ec the runtime changed in `sp_poly_dig_*` and strftime only, and no family program's C names either; from 26d456ec to 5390d300 `lib/` did not change.
- Master's C is the same from 8684d54c to 5390d300 for every program of both pieces' families and of the brief's set (1,800 + 1,188 + 924 + 300 + 180 + 197 = 4,589; the 121 of the supplement not measured on 8684d54c were run on 26d456ec). So none of these programs is cured, or raised, by master itself, and that is the count asked for: 0 of 4,589.
- This piece's rows: the ancestor family was measured on 8684d54c and 1,092 rows carried to 26d456ec (the 96 whose C the `chr` change below alters were run there); the family of 1,800, the brief's set, the clang rows of both and the cost were measured on 26d456ec; all carry to 5390d300 (C identical in every program), and the cost was measured again there. The tests ran on 5390d300.
- Upstream's three new tests (`test/boxed_walk_own_method_arity.rb`, `test/boxed_dig_receiver_checked.rb`, `test/boxed_handle_face_args.rb`) pass on master, on this piece and on piece 2, gcc and clang at the three stress levels, on 26d456ec and on 5390d300.
- Upstream's helpers. `builtin_arity_expected` answers what count a builtin's method takes. This piece wrote String#chr's count ("given 1, expected 0") out in its runtime helper: a second statement of the table's row. It is gone: the `chr` arm asks `builtin_arity_expected("String", "chr", ...)` and raises at the call, in the form `emit_walk_arity_raise` emits; `sp_poly_chr_enc_raise` keeps the Bignum's RangeError and the NoMethodError. `emit_walk_arity_raise` itself serves the walk of a builtin Enumerable copy, which none of these calls is. `ty_poly_handle_face_args` lists the names only a handle class answers at a count; `odd?`, `even?`, `~` and `chr` are not handle names (a MatchData, 7 and "s" boxed together: master has 10 of 23 lines wrong, this 0). The inverted list asks where the program defines a name; none of the three answers that, and `poly_name_user_claimed`, which master already had, still gates `~`.
- The newest master, d1081446 (06:09 UTC, four commits on): both pieces pick clean (trees 7d02112085ee and c2dabf017317). It changes `lib/` and `src/codegen.c` for every program (SIGINT and SIGTERM with no trap), so there the rows are a re-run, not a carry. Not built here.

Claims, each with gcc 13.3 and clang 18.1 at `SPINEL_GC_STRESS` unset, 1 and 2, CRuby 3.3.6 as the answer:

- The family of 1,800 programs (25 kinds of value, 6 calls: `odd?`, `even?`, `~`, `chr` with UTF_8, US_ASCII and BINARY, 8 shapes of receiver; `handover-cp/gen-piece1-family.rb`), master to this:

```
NOBUILD            -> same               24    (a class's own odd? or even? beside a boxed one: did not build on master, right here)
RAISE_WHERE_RIGHT  -> RAISE_WHERE_RIGHT  11    (a class's own ~: TypeError on master and here)
WRONG              -> WRONG              43    (~ on a Bignum 22, p of 0.chr(US_ASCII or BINARY) 20, a class's own ~ rescued 1)
WRONG              -> raise_same         984
WRONG              -> same               102
raise_diff         -> raise_diff         3     (nil.chr(enc) through a typed ivar)
raise_diff         -> raise_same         132
raise_same         -> raise_same         135
same               -> same               366
differs between stress levels: 0
rule (a)/(b) breaks: 0
```

  1,242 cured, 501 right before and after, 57 as on master, none lost.

- The ancestor family, 1,188 programs (22 places a definition can sit, 9 definitions, 6 values in the box; `handover-cp/gen-piece1-ancestors.rb`), master to this:

```
NOBUILD            -> NOBUILD            246
NOBUILD            -> same               72
WRONG              -> RAISE_WHERE_RIGHT  1     (class NilClass; def odd? = to_i.odd?; a boxed nil: NameError where master raised NoMethodError; Ruby false)
WRONG              -> WRONG              330   (as on master)
WRONG              -> raise_same         1
WRONG              -> same               139
same               -> same               399
differs between stress levels: 0
rule (a)/(b) breaks: 0
```

  The twelve definers that reach an Integer (object, kernel, basic, numeric, compar, modobj, modnum, integer, modint, prepint, toplevel, alias) and the four added by the coordinator's ruling (`define_method` in Object and in Integer, a `prepend` and an `include` made after the first call): for `odd?` and `even?` this piece's C is master's, byte for byte, in all 672 of their programs.
- Sibling shapes, 35 programs (`map(&:odd?)`, `select`, `count`, a block, an instance variable, a parameter, a global, `send`, `public_send`, `&.`, a rescue modifier): 28 cured, 3 right before and after, 4 not right: `p 955.chr(Encoding::UTF_8)` inspects as bytes (as on master); `chr(e)` with the encoding in a variable, and on a String, raise NoMethodError for ArgumentError (as on master); `v.method(:odd?)` on a String raises NoMethodError where Ruby raises NameError (master answered false).
- The brief's 197 programs: 43 wrong on master, 28 cured here, the other 15 are piece 2's; nothing right is lost; the same under clang.
- Under clang every row of both families and of the sibling shapes is the gcc row, program by program (3,023 of 3,023).
- Rule (a): 0 programs right on master are wrong, refused or non-building here. Rule (b): 0 that raised, crashed or did not build on master answer silently wrong here; 0 build failures became a crash.
- Cost on a hot call with an Integer in the box (callgrind, 2,000,000 calls, instructions a call against master, gcc / clang; on 26d456ec and again on 5390d300, the same cells): `odd?` -1 / -2, `even?` 0 / -2, `~` -2 / -2, `chr(Encoding::UTF_8)` -2 / 0.
- Corpus C against 5390d300 (`-c --no-line-map` over `test/`, `benchmark/`, `packages/*/test/` and optcarrot, 6,357 programs): 76 change (69 in `test/`, 7 in `packages/`), every changed line at one of the cured calls (264 lines after masking temp numbers); 0 benchmarks; optcarrot identical; 0 refusal changes. Seven more files differ only by the build tree's path or revision string. The 76 programs' tests and the 4 new tests pass at stress unset (80 of 80). At stress 1 and 2, 76 pass and four fail, the same way on master: `packages/ffi/test/ffi_libc.rb`, `ffi_nil_numeric_arg.rb` and `ffi_store_string.rb` abort at stress 2 ("the mark reached a freed slot"), and `test/hash_iterator_boxed_callable.rb` prints `{nil => 0}` for `{1 => 0, 2 => 0}` at stress 1 and 2. Those four are master's own; they go to the miner.
- The share-strings tests, run by hand as `make share-strings-test` runs them (`--share-strings`, stress unset and 1): 82 of 82.
- The four tests pass under gcc and clang at the three stress levels; on master three fail (39 of 71 lines, 5 of 12, and one does not build) and `test/boxed_integer_only_inherited.rb` passes. `tools/gate.rb check` on the staged change: exit 0.
- The fork's CI on this tree (head cf7f2ebe, ubuntu-latest / clang; the fork skips the -m32 and wasm lanes): green.
- Not run: `make gate` (no Ruby 4.0 here; the `.expected` files are CRuby 3.3.6's with `--enable-frozen-string-literal`, and the tests print an exception's class, never its message).

Not here (each as on master):

- A Float or a String in the box does not reach Numeric's, Comparable's, Object's or Kernel's definition of `odd?` or `even?`: master's boxed dispatch has no arm from a builtin's tag to an inherited definition, and the value is still read as an Integer.
- An inherited `odd?` or `even?` that answers a value that is no true or false (the reader's F6 and F7: `def even? = :obj` in Object, or in a module Object includes, and 8 in the box) does not build, on master or here; Ruby answers true.
- `~` on a boxed Bignum answers from its low 64 bits.
- Beside a class that defines `~`, the boxed receiver is read as before and the class's own `~` is not called.
- `p 0.chr(Encoding::US_ASCII)` prints "\u0000" where Ruby prints "\x00".

Two wrong answers of master become a raise Ruby does not make, and the body names the first: a boxed Regexp's `~` raises NoMethodError where master answered -1 (Ruby matches `$_`); `class NilClass; def odd? = to_i.odd?; end` with nil in the box raises NameError where master raised NoMethodError (Ruby false).

Corrected from the second form's fold: "sibling shapes: all cured" (the counts are above); the 24 programs of the family's first table row did not build on master and are right here, they were not "the same on both"; the cost cells are the ones above.
