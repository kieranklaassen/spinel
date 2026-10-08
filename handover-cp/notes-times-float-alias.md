# Notes: a boxed String or Array times a Float, with the alias arm, on master 3d629868df96

A delta against e9fd059e9e9010645eaec359938a9ea9ae1f5f53 (on 42557a3c0e7c, the tree of a1ab4dcad78b), for the reader of verdict 18. It answers F1, T1 and T2.

## F1: an alias of a builtin's method under `*`

    class String
      alias * +
    end
    p(pick(0, "ab") * pick(0, 2.5))     # Ruby and master: TypeError; the piece of record: "abab"

The stand-down asked `comp_program_defines_name(c, "*")`, which read the classes' method tables and the DefNodes. An alias of a BUILTIN's method is in neither. My own attack set had the program (`dy_alias_sym`, `dy_alias_method_str`) and I read it past: master prints other lines of those programs wrong, the table counted by program, and "wrong on both" hid a line that went from right to wrong. The attack tables are read by line now.

The cure is the reader's shape, widened by the inverted test: wherever the node table cannot show that `*` still names the builtin's method, the unit sets the flag and the fold is master's C. `comp_program_defines_name` (src/compiler.c, +26 -1) also answers 1 for

- an AliasMethodNode whose new name is `*` or is no literal (`alias * +`),
- an UndefNode that names it (`undef *`),
- a call of `alias_method`, `undef_method`, `define_method` or `define_singleton_method` whose first argument is `*`, as a Symbol or a String, or is no literal (`alias_method name, :+`).

`undef` is in the list for the same reason as the alias: after `class String; undef *; end` Ruby raises NoMethodError, master raises its TypeError, and the piece of record printed the repeat, through a function of its own.

The tree keeps no list of the `alias_method` calls: upstream's own walk of the same four kinds (`sce_program_reflects`, src/analyze_desugar.c) iterates the kinds as this does. The walk is one pass over the def, alias, undef and call nodes a program; optcarrot's compile goes from 8,351,805,314 to 8,352,021,301 instructions (callgrind), 0.003% more.

The index those iterations read (NT_FOREACH_KIND) listed a node retyped in place under its old kind until 3d629868df96 ("A node retyped in place is listed under its new kind"). The piece is built on that tip for this reason. On the build on 5d762fb16716 no program of mine showed a stale list (the 32 alias attacks and s1 to s3 answer the same on both builds), but there it could not be ruled out.

### The 32 alias attacks (attack-times-alias/, times-alias-table.txt)

Columns: Ruby, master, the piece of record, this piece; the line is the Float count's. Every line the piece of record changed where Ruby prints no repeat is master's again: a01 to a03, a07, a16, a18 to a20, a23, a31 (alias and alias_method, Symbol and String names, in String and in Array, `define_method(:*, instance_method(:+))`, an alias to `upcase`, a name that is no literal), a10, a11, a28, a29, a32 (undef and undef_method), a27 (`String.send(:define_method, n) { }` with a computed name). a08, a09 and a30 (an alias FROM `*`, an alias of another name, an undef of another name) are still cured. a13 and a22 (an alias in Integer, an alias in a program's own class) stand down where the piece of record answered Ruby's line: master's TypeError stays, a cure not taken. a04 to a06, a14, a24 raise master's NoMethodError for `alias_method` with a receiver, as before; a12, a15, a17, a25 do not build on master or with the piece.

On 3d629868df96: 25 print master's bytes, 3 are right (wrong on master), 4 do not build on either. `alias_method "*", "+"` with String names in String and in Array (s1, s2): master's TypeError, kept.

Two tests hold the two forms: test/poly_times_alias_star.rb (`alias * +` in String and in Array) and test/poly_times_alias_method_star.rb (`alias_method :*, :+`). Both are right on master and wrong on the piece of record.

## T1: the cost paragraph names the master of the build

"(callgrind, master 3d629868)". Measured there, bare tip against the piece, 15 programs, gcc and clang (cost-times/, the cells file cost-times-on-3d629868.txt): the whole runs differ by 0 to 57 instructions with gcc and by -833 to 45 with clang, over 200,000 to 1,000,000 calls each, which is 0.00 a call in every cell: Integer, Float and mixed pairs, a String or an Array times an Integer, the Array join, a Bignum, a Rational, an object's own `*`, the mixed loops. The cured call (`sf`) runs 485 (gcc) and 462 (clang) instructions a call; master raises at the first.

## T2: the false sentence

"A fold whose count is a typed Float, `[s, 2.5].inject(:*)`, still raises" is in neither the message nor the description (v3 dropped it from both; the description file on the handoff branch was the older one). The -v4 files are the ones to carry.

## The big counts

The reader's observations (out of memory for an Array times 3.0e9 and more, "string size too big" for a String) are the Integer count's own answers on master: reached, not made. No cure here.

## What was run on 3d629868df96

Both trees built from nothing (make rc 0; `nm lib/libspinel_rt.a` finds sp_poly_recur_hash_cycles). The bare tip does not cure it: test/poly_times_float_count and its 64-bit twin are wrong there in all 12 cells; the three stand-down tests are right, by design.

- The five tests: 30 of 30 cells (gcc and clang, SPINEL_GC_STRESS unset, 1, 2); with `--share-strings` all five right; `ruby tools/gate.rb check` with the piece staged: rc 0.
- The 41 attacks (attack-times/), by line: 8 programs wrong on master are right; 25 print master's bytes; 3 are cured in part (rt_bin, rt_edge, rt_kinds: 52 lines cured, none lost; the 5 lines left are an Encoding's or a Hash's inspect in Ruby 3.3's format, "string size too big" for Ruby's "argument too big", and a Symbol's or an Integer's `to_s` being UTF-8 on master, which the Integer count prints the same); 4 do not build on either; 1 right on both. Right on master and not with the piece: 0 lines.
- The family (gen-times.rb, 3,132 programs, gcc, SPINEL_GC_STRESS unset, 1, 2; times-family-table-on-3d629868.txt): 630 right on the bare tip stay right, 1,400 wrong there are right, 1,070 are wrong on both and 32 do not build on either, and those 1,102 print the same bytes at the three levels. Right lost: 0. No program's verdict differs between the stress levels. With clang, every third program (1,044): 675 right, 358 wrong, 11 not building, each program as with gcc.
- The corpus (6,497 programs of the tip, the C each tree emits, compared byte for byte): 6,470 identical, 27 differ, no refusal changes. Three of the 27 differ between any two trees, by the length of the tree's own path in a `require` line. The other 24 gain one line each, the flag set in the unit's init, and nothing else: the 15 of the piece of record and 9 more. Eight name a method by an interpolated String or a variable in `define_method` or `undef_method` (test/compile_time_define_method_int, _predicates and _strings, computed_undef_beside_string_class_eval, define_method_capture_visibility, define_method_each_block_params, define_method_unrolled_name_block_next, next_in_run_once_block). The ninth, test/respond_to_object_methods, has no such call: for `x.respond_to?(:define_singleton_method)` (and `:define_method`, `:alias_method`, `:undef_method`) master builds a probe call of that name with an Integer argument, and the walk reads it as a name that is no literal. A name that is no literal counts as `*`: such a program keeps master's TypeError for a Float count, the safe side, a cure not taken. The emit ran with no time or memory bound.
- Optcarrot: the generated C is identical (cmp). Its run: 3,225,967,056 to 3,225,852,322 instructions with gcc (0.004% fewer, all of it in `sp_PolyPolyHash_get`, which the change does not touch) and 2,750,035,023 to 2,750,034,974 with clang; checksum 59662 on all four.

## Texts

times-float-count-commit-message-v4.txt and times-float-count-pr-body-v4.md: the stand-down paragraph names the alias, the undef and the names that are no literal; the tests are five; the master named is the build's. The title is v1's.
