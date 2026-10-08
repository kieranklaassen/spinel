<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
a = [+"ab=", 1]
p a[0].sub!("=") { "=" }     # nil, CRuby: "ab="
p a[0].gsub!(/b/, "b")       # nil, CRuby: "ab="
```

A plain run, gcc and clang.

The cost: a boxed `sub!` or `gsub!` whose answer is read and that matches nothing takes 4 to 6 instructions more a call with two arguments and 2 to 3 more with a block (callgrind, 200,000 calls, gcc and clang). One that matches takes about 100 fewer, since the match answers before the texts are compared. A call written as a statement and every call on a String receiver compile to the C they did.

`sub!` and `gsub!` answer nil when no substitution was made. For a boxed receiver (a String read out of a mixed Array or Hash, an Array of Strings, a method's boxed value) the answer came from comparing the text before and after, so a substitution that wrote the bytes it found answered nil.

A String receiver's call answers by its own match: its plain form enters the runtime through a wrapper that clears the matched flag after the operands have run, and a block form answers from a local of its loop. The boxed arm now names its call the same way and takes that answer beside the comparison. This sits above "sub! and gsub! answer by their own match, not by an argument's" and needs it: the wrapper and the local are that pull request's.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"ab="
-"ab="
+nil
+nil
```

Two commits. The first is a refactor with no change in generated C (`tools/cident.sh`): the marker `emit_stmt` sets for the setter call it lowers, `g_setter_stmt_id`, becomes `g_stmt_call_id` and is set for any call that is a statement. The second is the fix; it asks that marker, so a call nobody reads the answer of pays nothing.

Test: `test/boxed_sub_bang_same_bytes.rb`.

Not here. A substitution that wrote the same bytes still answers nil on a boxed receiver when:

- the replacement is a Hash (`a[0].sub!("=", { "=" => "=" })`), which no wrapper serves;
- the call is the last one of a block given to a method that yields (`def y = yield`, then `y { a[0].sub!("=", "=") }`), which is lowered as a statement.

A block passed as `&blk`, a lambda or a method object raises NoMethodError, as before. A block that appends to the receiver (`a[0].sub!("=") { a[0] << "x"; "=" }`) raises RuntimeError in CRuby; here it answered nil and now answers the String.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
