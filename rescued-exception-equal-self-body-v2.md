<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An exception was not `equal?` to itself when one side was the rescued value
and the other the same object typed as the program's own class, and `==`
said the same.

```ruby
class MyErr < StandardError; end
k = MyErr.new("n")
begin
  raise k
rescue => e
  p e.equal?(k), k.equal?(e), e == k
  # Spinel: false false false; CRuby: true true true
end
```

`rescue MyErr => f; p f.equal?(f)` printed false too. A value typed as a
class the program puts under an exception and a rescued exception are the
same `sp_Exception` pointer, but each arm knew one of the two types:
`Object#equal?` answered false for any argument that is not a plain object,
and the exception receiver's `==`, `eql?` and `equal?` answered false for an
argument typed as the class. Both arms compare the two addresses now.

By address only, and this is why:

```ruby
o = MyErr.new("n")
begin
  raise MyErr, "n"
rescue => e
  p e == o    # false in CRuby, false before and after this change
end
```

Another exception of the same class and message is not `==` in CRuby: it
compares the backtraces too, and a rescued exception has one the other
object does not share. `sp_exc_eq` compares class and message, so sending
the pair to it would have turned this right answer into true.

Not here:

- `k != e` with the typed value on the left is still refused ("unsupported
  equality").
- An exception never raised and kept as a boxed value (in a mixed Array) is
  asked as before.

Test: `test/rescued_own_exception_equal.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
