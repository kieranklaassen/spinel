<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A method called straight on a bare `Array.new` answered nil with nothing said, or raised NoMethodError at run time, where `[]` was right.

```ruby
p Array.new.join
p Array.new.sum
p Array.new.include?(1)
```

`spinel diff` on master:

```
spinel diff: exception-diff
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'include?' for unknown

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,2 @@
-""
-0
-false
+nil
+nil
```

A bare `Array.new` infers no type, like `[]`, so that a later push can settle its element kind. As a receiver it has no later use, and only the empty literal had the arms for that. `desugar_class_literal_ctors`, which already builds the literal for `Array[a, b]`, now builds it for an `Array.new` with no argument and no block under a call that answers a plain value and reads nothing but literals:

- `size`, `length`, `empty?`, `nil?`, `frozen?`, `inspect`, `to_s`, `first`, `last`, `min` and `max` with no argument;
- `count`, `any?`, `all?`, `none?` and `one?` with none or one literal;
- `include?`, `member?`, `==`, `!=`, `index`, `find_index` and `rindex` with one literal;
- `at` and `[]` with one Integer, `dig` with Integers;
- `join` with none or a String, `sum` with none, an Integer or a Float;
- `fetch` with an Integer and no default, or a literal default that is no String.

Checked:

- `test/array_new_receiver_is_empty_literal.rb` does not build on master dafa0d047 and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 2,256 generated programs, each against CRuby and beside its `[]` twin on master (9c4eec71e): the generated C changes in 831 of them, 277 forms in three places (printed, through a variable, in a branch not taken). All 831 are right here and right on `[]` on master; 476 of them raised or were wrong on master. No program that was right is lost.
- Generated C across `test/`, `benchmark/` and `packages/*/test/` on dafa0d047: 6,279 of 6,281 programs are byte-identical. The two that differ are the new test and `test/array_new_bare_receiver.rb`, which calls `Array.new.size` and answers as before.

Left alone, compiled as before:

- A call with a block or with an operand that has to be run (`Array.new == Array.new`, `Array.new.all?(f)`).
- A call that stores into the Array, and one that answers an Array or a container: what is done with that Array later would meet the literal's own arms. `Array.new + [1]` and `Array.new.sort` still answer nil, and `Array.new.map { }` still raises NoMethodError.
- Twelve literal forms where `[]` itself is wrong on master: `join` with true, false or an Integer; `sum` with a Symbol, nil, true or false; `at`, `[]`, `dig` and `fetch` with an Integer past int64.
- Every call where the program gives Array a `new` or an `initialize` of its own.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
