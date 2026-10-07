<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String that `h[k] ||= v` stores into a Hash is now stored as `h[k] = v` stores it, and it compiles in that store's time: a row of 512 such or-writes into one Hash takes 2.31 s where it took 0.08 s (written with `=`, 1.32 s on master); a row of eight takes no time that shows. The table is below.

```ruby
u = {}
%w[a b a].each { |w| u[w] ||= +""; u[w] << w }
p u.to_a
```

```
spinel diff: output-diff
  program: witness.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[["a", "aa"], ["b", "b"]]
+[["a", ""], ["b", ""]]
```

That is master (8dc552254), in the default build and under `--share-strings`. Every append goes to a copy. Written `u[w] = +"" unless u.key?(w)` the program is right, and so is `u[w] || (u[w] = +"")`.

`h[k] = v` stores a String as the handle an in-place change through the index needs. The or-write emitter has a store of its own, which boxes the String as a plain value, so the read hands `<<` a copy; `concat` on it raises NoMethodError.

The index or-write of a program class is already rewritten to what Ruby defines it as, `h[k] || (h[k] = v)` (`desugar_index_assign_user_recv`). The same rewrite is now taken for a Hash, only where it is the same program:

- the value is a String;
- the receiver is a local that is no parameter, or an instance variable where the write is a statement;
- every write of that variable gives it `{...}` or `Hash.new`. The receiver's type is not asked: it is a guess while the fixpoint runs (`c = []; c[0] ||= s` is a Hash of Integer to String for a round), and a rewrite made on the guess stays;
- the receiver and the key are read without effect (the rewrite's own rule).

Every other or-write keeps the emitter's store and its generated C. So a Hash of counters (`c[k] ||= 0; c[k] += 1`), of Arrays (`(u[k] ||= []) << x`) and a memo of Integers are compiled as before, and the Hash keeps the type master gives it.

Of 4,307 programs around an index or-write (measured on 759d120fd; the 361 of them run again on 8dc552254 give the same rows), in the default build 3,068 keep their C and 79 their refusal; of the 1,160 that change, 738 printed a wrong answer and print the right one, 18 raised and print the right one, 321 stay right, 4 that were wrong are refused ("a String stored in a Hash is passed to an appending value block") and 79 stay wrong, 72 of them `(h[k] &&= v) << x`. Under `--share-strings` 3,015 keep their C and 132 their refusal; of the 1,160 that change, 584 were wrong and are right, 18 raised and are right, 77 were refused and are right, 442 stay right and 39 stay wrong. None that is right is lost or refused.

**Compile time.** The rewritten write is a store the analysis walks, as it walks `h[k] = v`. `spinel -c`, user and system seconds, the lower of three:

| or-writes into one Hash | master | this | written with `=`, master |
|---|---|---|---|
| 128 `h["kN"] \|\|= +""` | 0.02 | 0.14 | 0.09 |
| 512 of them | 0.08 | 2.31 | 1.32 |
| 512, each appended to (`h["kN"] << "!"`) | 0.47 | 4.14 | 3.92 |
| 512 `h["kN"] \|\|= h["kN-1"]` | 0.16 | 6.09 | 4.89 |
| 512 `h[:kN] \|\|= +""`, each appended to | 0.37 | 0.94 | 0.60 |

**Not here**, each printing what it prints on master:

```ruby
def fill(c)
  c[:k] ||= +""            # a parameter's Hash: `c[:k] = +""` is refused there
end

class Index
  def slot(k)
    @by[k] ||= +""          # the write as a value on an instance variable
  end
end

h[k.to_s] ||= +""           # a key that is a call
a[0] ||= +""                # an Array's slot
h = make                    # a Hash a method answered, or `h = h.merge(x)`
h[:k] ||= +""
```

`tools/cident.sh 8dc552254`: 6441 identical, 7 differ, 0 refusal changes. The 7 are the new test, the four tests that print the compiler's revision, and two tests with a String or-write into a Hash (`test/container_read_missing_arms.rb`, `test/hash_or_and_assign_default.rb`), which print their `.expected` with the new C in both builds, at `SPINEL_GC_STRESS=2` too. `make share-strings-test` passes, and `make scale-test` gives master's four ratios (1.71, 4.74, 6.13, 4.17).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
