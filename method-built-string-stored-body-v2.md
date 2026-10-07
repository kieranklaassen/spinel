<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class K
  def initialize(s) = @s = s
  def e = @s.dup
end
x = [K.new(+"hello").e]
x[0] << "!"
p x                 # ["hello!"]
```

died with SIGSEGV built with gcc and did not build with clang. So did `x << k.e` and `{a: k.e}`, and any method whose body builds its String: `"#{@a}-#{@b}"`, `@n.to_s`, `@s.upcase`.

An element that is appended to is stored as a String handle. `strbuf_marked_yields_handle` took every call on an object for a reader, which renders as the handle itself, so a method answering a plain `const char *` had that pointer boxed as a handle and the append wrote through it.

Such a call is now wrapped as a fresh handle where it is stored, as a String call that makes a new String already is (`[s.upcase]`). It is taken only where the method's body is seen to end in a String it makes: an interpolated String, `to_s`, `inspect` or `chr` of an Integer or a Float, or a String method that always answers a new String. A subclass's method of the name must do the same, and a name that is also an attr reader is left as it was. A nil the method answers (`def m = @x&.upcase`) is stored as nil. Every other call renders as before.

No String is shared that was not, and nothing is refused that was not. The reproducer does the same with `--share-strings`: SIGSEGV before, right after.

Not changed: a call that is not seen to build its String. A method that hands out the object's own String (a reader, `def s = @s`, `@s.itself`, `@f ? @s : @s.dup`, a body that ends in `@s << "?"`) is refused or crashes exactly as on master.

Not here: a program that died at this store now runs on, so a wrong line master already prints further down shows. `z = [k.e]; z.concat([k.e]); z[1] << "?"` loses the append, as master does today with `"hello".dup` written in the calls' place. What makes that line wrong is the copy the second String went in as (by `concat`, `insert`, a splat, or a later link of a push chain), which this does not touch.

`tools/cident.sh` against d1081446b: 6359 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
