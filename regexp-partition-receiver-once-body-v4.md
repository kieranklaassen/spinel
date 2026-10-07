<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`partition` with a Regexp evaluates its receiver twice when nothing matches:

```ruby
$calls = 0
def line
  $calls += 1
  "row" + $calls.to_s
end
p line.partition(/z/)   # ["row2", "", ""]; CRuby prints ["row1", "", ""]
p $calls                # 2; CRuby prints 1
```

`spinel diff` of that program on 185c4d663:

```
spinel diff: output-diff
  program: partition_twice.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-["row1", "", ""]
-1
+["row2", "", ""]
+2
```

`(s = s + "c").partition(/z/)` assigns twice and `(s << "c").partition(/z/)` appends twice in
the same way.

The emitter builds the Array in the emitted C, and it wrote the receiver's C text twice: once
for the match, and once more for the first piece when nothing matches. Now the receiver goes
into a C temporary and both places read that. Nothing else in the emitted C moves: the Array,
the match and the pieces are made in the order they were, so `$~`, `$1`, `` $` `` and `$'` read
the same. The temporary needs no root: nothing allocates between a match that fails and the
copy, and `sp_str_dup` roots what it copies.

The arm is the one taken wherever the compiler can name the Regexp: a literal, and a local or a
constant that holds one (`re = /z/; p line.partition(re)` ran `line` twice too), also through
`send` and `public_send`, on a boxed receiver and on a Symbol's `to_s`.

Measured on dafa0d047 with gcc 13.3 and clang 18.1, the runtime built with each; both compilers
give the same counts. On 185c4d663 the commit picks clean and the test was run again:

- `test/regexp_partition_receiver_once.rb` prints 9 wrong lines without the change, in a plain
  run and under `SPINEL_GC_STRESS` 1 and 2. With the change it is right at all three, with
  `SPINEL_GC_VERIFY` 0 and 1. `make gc-stress-test` passes.
- Of the 6,773 Ruby files under test/, benchmark/, examples/ and packages/, 6,533 compile, and
  the C of two changes: test/string_partition_regex_and_puts.rb and
  test/string_unchanged_result_is_new.rb. Both are right without and with the change at 0, 1
  and 2.
- A set of 1,224 programs, one case each, built and run on both: the receiver written 23 ways (a
  local, a literal, a call, `q.pop`, an assignment, an append, a reader that counts its calls, an
  800 KB String, binary, with NUL bytes), nine patterns, the match read afterwards through `$~`,
  `$1`, `` $` ``, `$'` and `Regexp.last_match`, the result used 18 ways; the Regexp held in a
  local or a constant, the call made through `send` and `public_send`, on a boxed receiver and
  on a Symbol's `to_s`; a piece appended to, frozen, asked its encoding and walked with
  `Enumerator#next`. The C of 1,142 changes, in the partition expression alone. The C of the
  other 82 does not change: rpartition, split and partition with a String (66), and partition
  with a Regexp the compiler cannot name (16, below).
  - In a plain run and under levels 1 and 2 alike, 74 answer wrong without the change and are
    right with it, each one a receiver that ran twice.
  - Every other program prints, at each of the three levels, byte for byte what it prints
    without the change. Two that are wrong on both (an append to a piece, below) differ in the
    one line the change cures.
- Cost (callgrind, 100,000 calls): `"key=value".partition(/=/)` goes from 1,139 to 1,140
  instructions a call and a subject with no match from 1,141 to 1,142.

Left alone, the same without and with the change:

- An append to a piece does not show: `r = "abc b1".partition(/Q/); r[0] << "!";
  p r[0].bytesize` prints 6 where CRuby prints 7 (24 programs of the set).
- A piece of a binary String is taken for UTF-8: `"ab \xff cb".b.partition(/b/)[0].encoding`
  answers UTF-8 where CRuby answers ASCII-8BIT (7 programs).
- A nil receiver answers: `v = {"k" => "abc"}["none"]; p v.partition(/b/)` prints
  `[nil, "", ""]` where CRuby raises NoMethodError (1 program).
- A binary String against a multi-byte Regexp answers where CRuby raises
  Encoding::CompatibilityError (1 program).
- A Regexp the compiler cannot name (a parameter, an instance variable, `Regexp.new`, a literal
  with an interpolation) raises TypeError, "no implicit conversion of Regexp into String"
  (16 programs).
- A caller's `$1` goes stale after many calls of a method that matches a capturing Regexp
  (1 program):

  ```ruby
  def cut(s)
    s.partition(/(b)(c)?/)
  end
  "k9" =~ /k(\d)/
  i = 0
  while i < 2000
    cut("abc b" + i.to_s)
    i += 1
  end
  p $1          # "bc"; CRuby prints "9"
  ```

  It is right up to 1,373 rounds and wrong from 1,374 in a plain run, and wrong from 194 under
  `SPINEL_GC_STRESS=1`; at level 2 it aborts. With `s.sub(/(b)(c)?/, "x")`
  as the method's body `$1` goes stale the same way.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
