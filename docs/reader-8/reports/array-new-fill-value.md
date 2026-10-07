# Second reading: "Array.new(n, value) holds a value made in place while the Array is made"

Piece: branch `claude/array-new-fill-value-rooted-on-26d456ec`, head
92965f19c4513b4987d01bf79b5a9d371b48f562 (one commit on 26d456ec1035, tree
9f904ae75124). Texts on `claude/pr-text-handoff`:
array-new-fill-value-rooted-title.txt, -commit-message.txt, -body-v2.md.
Builder: the thread "Append to a parameter taken through &&".

Read on upstream master 5390d3002886d785ea1c74f77380f96e9096ebf0 (the piece
merged into it: tree 09bf4fa571e7; both built here, gcc 13 and clang).
CRuby 3.3.6 with `--enable-frozen-string-literal` is the reference.

## VERDICT

NOT READY, by the piece's own turned test, on one entry of its held list;
the repair is one line and is measured below. No rule (a) row, no rule (b)
row. Everything else is PASS WITH TEXT FIXES.

1. AN-1 (the held list). `self` is on the list of values "something else
   holds" (`NK_SelfNode` in `array_fill_value_held`), and the texts do not
   name it ("a variable or a constant holds what is read from it, and a
   literal String is static"). In a method the program adds to a builtin
   class nothing holds `self` when the receiver was made in place. The
   body's own reproducer with the fill moved into such a method is still
   wrong in a PLAIN run on the piece, with master's C byte for byte.
2. AN-2 (text, cost). The sentence on a root that may not be needed gives
   its cheapest case. A conditional of two locals costs 7.2%.
3. AN-3 (text). "Not here" names `Range.new(s + t, s + u)`; the Range
   literal `((s + t)..(s + u))` fails the same way on master and here.
4. AN-4 (text). The numbers are on 26d456ec; upstream has moved, and
   upstream's later commit "The builtin modules are modules: Math.class is
   Module" changes `emit_new_call_arms` (another arm). The piece still
   merges clean (see "On the tip").
5. AN-5 (reached, not cured). With a size that allocates and a value that
   is a `begin` block, the value is made BEFORE the size is run and nothing
   holds it meanwhile; the root comes after. Master is wrong under stress 1
   and stops under 2; the piece is right under 1 and still stops under 2.
   Moving one line of the arm cures it and puts the two in CRuby's order.

## AN-1: `self` is on the held list and is not held

```ruby
class String
  def twice = Array.new(2, self)
end
s = "abc"
t = "def"
u = "xyz"
rows = []
3000.times do
  rows << (s + t).twice
  z = s + u
  z = u + s
end
p rows.uniq
```

| | plain | `SPINEL_GC_STRESS=1` | `SPINEL_GC_STRESS=2` |
|---|---|---|---|
| CRuby 3.3.6 | `[["abcdef", "abcdef"]]` | | |
| master 5390d300 (gcc, clang) | `[["abcdef", "abcdef"], ["xyzabc", "xyzabc"]]` | three rows | the mark reached a freed heap string |
| the piece (gcc, clang) | the same as master | the same | the same |
| the piece without `NK_SelfNode` in the list | right | right | right |

The generated C is the same on master and on the piece:

```c
sp_String_twice(const char *self) { ... const char * _t3 = self; sp_StrArray *_t4 = sp_StrArray_new(); ...
```

`self` is a C parameter with no root; the caller made `s + t` in place and
holds it nowhere. The twin that copies first, `x = self; Array.new(2, x)`,
is right on both trees at every level, so the cause is this arm's
temporary and nothing else.

Where it holds (each right with the copy-first twin on master, wrong or
stopped with `Array.new(n, self)` on master and on the piece, 24 Arrays
kept, gcc):

| the method is added to | receiver made by | plain | stress 1 | stress 2 |
|---|---|---|---|---|
| String | `s + t` | right (wrong at 3,000) | wrong | stops |
| String, through `alias`, or with `n` a parameter | `s + t` | right | right or wrong | stops |
| Array | `(s + t).chars` | right | 19 of 24 wrong | right |
| Array | `pair(s + t)`, `g.dup`, `[s] + [t]` | right | right | stops |
| Hash | `{...}.merge({...})` | right | wrong (loud at 3,000) | stops |
| StandardError | `RuntimeError.new(s + t)` | right | right | stops |
| Proc | `proc { s + t }` | right | right | stops |
| Object, Kernel (String receiver) | `s + t` | right | right or wrong | stops |

Right on master and here: `self` of a class of the program's own (also one
that inherits StandardError), a Struct, a literal Array or Hash receiver,
Symbol, Integer, Float, Regexp, the top-level `self`, a subclass of Array.

**The repair, measured.** Taking `NK_SelfNode` off the list (one line;
tree an5x here) roots the temporary for `self`. Of my 76 `self`
probes, 29 programs change: 27 are then right at all three levels and two
(the fill inside a block of the method) gain one row; 39 rows made right,
none worse. The other 47 are the same on both. Cost: `Array.new(2, self)`
in a class's own method, 200,000 times, 38,907,012 instructions on the piece and 39,120,253
with the line removed.

The cause under it is master's and wider than this arm: in a method added
to String, `[self, self]`, `a << self`, `[nil, nil].fill(self)` and
`[self] * 2` fail the same way (side find 1). The one line cures only
`Array.new(n, self)`; the texts should say which they choose: root `self`
here, or name `self` in a method added to a builtin under "Not here".

## AN-2: the cost sentence gives its cheapest case

Body: "A value that is neither proved held nor seen to be made in place
takes a root it may not need: a Regexp literal and a Bignum literal ...
`Array.new(2, /ab+c/)` 200,000 times: 38,939,404 and 38,943,197."

Every value that is not a plain read takes the root, and most are of
pointer kinds. Measured here on 5390d300, 200,000 fills, callgrind:

| value | master | piece | |
|---|---|---|---|
| `s + t` | 103,487,632 | 107,097,555 | the cure |
| `"#{s}#{t}"` | 92,685,168 | 96,896,220 | the cure |
| `[s, t]` | 79,888,297 | 79,909,146 | the cure |
| `Object.new` | 48,674,940 | 48,891,787 | the cure |
| `/ab+c/` | 38,859,657 | 38,863,473 | not needed |
| a Bignum literal | 50,110,421 | 49,922,877 | not needed |
| `k > 2 ? s : t` (two locals) | 47,156,216 | 50,558,595 | not needed, +7.2% |
| `[s][0]` | 82,967,666 | 86,169,179 | not needed (the Array is made in place, the element is held by it only) |
| `s`, `"lit"`, `7`, `nil` | 47,156,202; 46,756,218; 59,082,258; 36,849,283 | the same C | |

The sentence should give the conditional's number, or say "up to 7% on a
fill whose value is a conditional of two reads".

## AN-3: the Range literal is beside `Range.new`

```ruby
rows << ((s + t)..(s + u))
```

kept 24 times between other allocations: right plain, wrong under
`SPINEL_GC_STRESS=1`, stops under 2, on master and on the piece, the same
as `Range.new(s + t, s + u)`. The body and the commit message name only
`Range.new`.

## AN-4: the numbers are on an older master

The body's table, cident line and cost are on 26d456ec. On 5390d300 I get
the same shape (see Counts). Upstream is now a39414338a22; its commit "The
builtin modules are modules: Math.class is Module" changes
`emit_new_call_arms` (the NoMethodError arm at its end), so by the
coordinator's rule the builder's line is rebuilt there.

## AN-5: an allocating size with a `begin` value is not cured

```ruby
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do |i|
  rows << Array.new((s + u).size - 4, begin; s + t; end)
  z = s + u
  z = [u + s, z]
end
puts rows.size
puts rows.count { |r| r != ["abcdef", "abcdef"] }
```

CRuby prints 24 and 0. Master 5390d300 (gcc): right plain, a wrong count
under `SPINEL_GC_STRESS=1`, the mark reached a freed heap string under 2.
The piece (gcc and clang): right plain and under 1, still stops under 2.
The piece's C:

```c
const char * _t12 = NULL;
_t12 = sp_str_plus(lv_s, lv_t);
sp_int _t8 = sp_int_sub(sp_str_length_m(sp_str_plus(lv_s, lv_u)), 4LL);
if (_t8 < 0) sp_raise_cls("ArgumentError", "negative array size");
const char * _t9 = _t12;
SP_GC_ROOT(_t9);
sp_StrArray *_t10 = sp_StrArray_new();
```

The arm calls `expr_buf(c, argv[1])` before it writes the size's line, so
what the value hoists runs first; `_t12` is held by nothing while the size
allocates. The same with `begin; s + t; rescue; u; end`. In my family the
five programs of this shape (five sizes that allocate, the `begin` value)
are the only ones of 198 with an allocating size that are not right on the
piece; the other 21 values with the same sizes are right. Of 15 further
statement-shaped values with an allocating size, master fails 7 (wrong
under 1, stops under 2), the piece cures 5 and leaves these two.

The body lists "`begin`" and "n itself allocating" among the 26 further
forms that are right; each alone is, the two together are not.

**A repair, tried.** Writing the size's two lines before
`Buf vb = expr_buf(c, argv[1]);` (one line moved; an5x here, with AN-1's
line too): the five and the two are right at all three levels, and the
order is CRuby's (side find 2). Run on those 21 programs and the order
program only; not on the families, no cident.

## Text, sentence by sentence

Confirmed here on 5390d300:

- The reproducer and its `spinel diff` report: two rows plain on master
  (gcc and clang), three under stress 1, the mark stops under 2; the piece
  right on 12 rows.
- "Two tests of the suite have the shape": `test/array_new_container_default.rb`
  stops under stress 2 on master; `test/bundle_class_21.rb` prints
  -2604246222170760229 three times and exits 0. Both right on the piece.
- The test: `.expected` equals CRuby 3.3.6 (13 lines); master has 2 lines
  wrong plain, 5 under stress 1, and stops under 2 (gcc and clang); the
  piece differs on none of 6 rows, also under `--share-strings` and with
  `SPINEL_GC_VERIFY=1` at both levels.
- "Those keep their C": 139 of my 646 programs have the same C on both
  trees (every kind of read: parameters, block and lambda parameters,
  instance, class and global variables, constants, cells, rescue and
  pattern bindings, by-value Structs, literals, Integer, Float, Symbol,
  nil).
- "a Range enters an Array of mixed values through a box that copies it":
  read in the code (`boxed && vt != TY_POLY && (!needs_root(vt) ||
  comp_ty_value_obj(c, vt))`), and the rows of ty_range, ty_time,
  ty_rational, ty_vstruct below.
- The other boxes do not allocate: `sp_box_str`, `sp_box_nullable_obj`,
  `sp_box_ptr_array_k`, `sp_box_bigint` (read in lib/sp_alloc.h and
  lib/sp_cold.c).
- "Not here": of 26 neighbouring forms on master only the cured form with
  `.first(2)` after it, `Range.new` and the Range literal fail; the block
  form, `Hash.new(s + t)`, `[s + t] * 2`, `fill`, `String.new`, `Set.new`,
  a Struct's and an object's `new` are right at every level.

Not confirmed (the builder's own): the 560 programs and the 57.

## Counts

646 programs of my own (gen_an.rb), each keeping 24 Arrays between other
allocations, expected "24" and "0"; four families: h, the value read from
a holder of every kind (138); n, nine sizes (a literal, a local, six that
allocate, a block) by 22 values (198); pl, 37 places for the Array by three
values (111); ty, 25 kinds of Array by eight uses (199). Rows are (program,
stress unset, 1, 2), one build with gcc.

- C the same on master and the piece: 139 programs (one more is refused by
  both, `$*`). On master: 138 right on 3 rows each; 1 is AN-1's
  (`Array.new(2, self)` in a method added to String: right, wrong, stops).
- C changed: 506 programs, 1,518 rows on the piece: 1,510 right, 2 wrong
  and silent, 6 stop. 500 programs are right on all three rows. The six:
  the five of AN-5, and `Array.new(2, ((s + "")..(t + "")))`, a String
  Range literal whose ends are made in place (AN-3's cause, in the Range's
  own arm; right plain and under 1, stops under 2).
- The six on master (gcc): five are right, wrong, stops; the Range one is
  right, right, stops. So of the 18 rows: 5 wrong made right (gcc; 3 with
  clang), 0 right made wrong, 0 stop made a wrong answer. Rule (a) rows: 0.
  Rule (b) rows: 0.
- The piece with clang on the six: four are right, right, stops; two are
  right, wrong, stops.
- A fifth of the 506 on master (102 programs, gcc): 47 right on all rows,
  55 not (20 wrong under stress 1, 55 stop under stress 2, none wrong
  plain at 24 kept); on the piece 54 of the 55 are right on all rows and
  one (AN-5's) gains its stress 1 row: 74 rows made right, 231 right on
  both, 1 the same failure, 0 worse.
- A third of the 506 on the piece with clang (169 programs): 168 right on
  all rows; the one is AN-5's (right, wrong, stops).
- `self` probes (76 programs, hand-written): AN-1.
- Neighbouring forms (26) and the two suite tests: under "Text".
- Held reads beyond the family (28 probes): parameters of a method added
  to String, Array, Integer; `$!`, `$0`, `$PROGRAM_NAME`, `__FILE__`,
  `RUBY_VERSION`, `RUBY_PLATFORM`; an instance variable and `self` of an
  exception class of the program's own; the top-level `self`: right on
  both trees at every level.

## Tools, on 5390d300

- `CIDENT_JOBS=3 make cident REF=5390d3002886`: 6350 identical, 7 differ,
  0 refusal changes, 0 refused by both, 0 not in the reference. The seven:
  the new test, `test/array_new_container_default.rb`,
  `test/bundle_class_21.rb`, and the four programs that print the revision
  stamp (a local merge commit: frozen_chilled_builtin_strings,
  object_scoped_ruby_constants, ruby_description_shape,
  symbol_id2name_ruby_desc_minmax).
- `make share-strings-test`: pass. `make reject-test`: pass.
  `tools/refusals.sh`: pass (534 records).
- `ruby tools/gate.rb check` with the commit staged over 5390d300 in a
  scratch tree: exit 0; its one line is "no Ruby 4.0 or later".
- Compile of the piece's own test (callgrind): 333,909,866 on master,
  333,994,231 on the piece.

## On the tip

Upstream master a39414338a22 (ls-remote, 07:42 UTC 10-07): the commit
merges clean (tree c51cd67cd6b9). Not built there.

## NOT run

- The whole gate (`make gate`), `make gc-stress-test`, scale-test.
- CRuby 4.0 (not installed here).
- optcarrot.
- The whole 506 on master and with clang: a fifth on master and a third
  with clang were run (see Counts).
- The two tried repairs on the families, and their cident.

## Side finds on master 5390d300 (for the miner)

1. In a method added to String, `self` of a receiver made in place is held
   by nothing: `[self, self]`, `a << self`, `[nil, nil].fill(self)`,
   `[self] * 2`, a block that reads `self` (`[1].map { ... self ... }`),
   each with `(s + t).twice` kept 24 times: right plain, wrong under
   stress 1 or stops under 2. `Array.new(2, self)` is AN-1.
2. `Array.new(n, v)` runs the hoisted part of `v` before `n`:

   ```ruby
   def note(x)
     puts "n#{x}"
     x
   end
   c = Array.new(note(2), [note(4), note(5)])
   ```

   CRuby prints n2 n4 n5; master and the piece print n4 n5 n2. The same
   with `[1].map { |i| note(7) }.first` and `note(8).then { |v| v + note(9) }`
   as the value. Silent, plain run.
3. The Range literal of AN-3.
4. `(s + t).both(s + t)` with `def both(o) = [Array.new(1, self)[0], o]`
   added to String: wrong under stress 1, stops under 2, also with `self`
   rooted in the method. Inferred, not traced: the receiver made in place
   is not held while the argument is made.
5. `(s + t).to_sym` kept in an Array prints `:??????` under stress 2
   (`[:??????, :??????]`, exit 0): the Symbol's name is freed.
6. `class Range; def tw = Array.new(2, self); end` called on
   `((s + t)..(s + u))`: "undefined method 'tw' for an instance of Array
   (NoMethodError)".
7. `module Comparable; def tw ... end` called on a String: NoMethodError.
8. A method added to MatchData is refused ("unsupported MatchData
   method"); `def fillwith(o = self + "!")` added to String does not build
   in C ("'self' undeclared"); a method added to String that yields `self`
   to a literal block does not link.
9. `class MyErr < StandardError; def tw = Array.new(2, message); end`:
   "undefined local variable or method 'message' for an instance of MyErr"
   (the ground of the thread "Bare message inside a custom error class").
