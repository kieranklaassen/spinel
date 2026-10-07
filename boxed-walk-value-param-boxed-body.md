<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A walk with two block parameters over a receiver that may be a Hash or an Array segfaulted in a plain run when its block pushed onto the value:

```ruby
def pick(n) = n > 0 ? {a: 5} : [1, 2]
h = pick(1)
x = "!"
h.each { |k, v| v << x }   # segfault; CRuby raises TypeError
```

The fix has a cost. Of 1,296 programs of this shape, 665 are right on master and 20 of those now raise master's own TypeError, "cannot store String into an Array[Integer]". All 20 are one shape: a String pushed onto an Integer Array held as a Hash value, the Array never read after. The smallest:

```ruby
def pick(n) = n > 0 ? {a: [1]} : [1, 2]
h = pick(1)
x = "!"
h.each { |k, v| v << x }
puts "done"                # master: done; now: TypeError
```

Master is right there only because it drops the push: with `p h` as the last line it prints `{a: [1]}`. Another 55 programs with that push raise the same error where CRuby pushes; 45 of them did not build and 10 printed the dropped push. It is the limit master already has: master raises the same for the same statement wherever another line types the receiver (add `h[:a]` as a last line above).

The cause. While `h` is still untyped the push types `v` an Array of Strings. Once `h` is boxed every parameter of a boxed walk is bound boxed, but a slot already typed an Array was skipped, so each boxed value was read as an Array of Strings: a segfault for `each` and `each_pair`, C that did not build for `map`, `select` and `reject`. The walk's one-parameter path already makes the exception for a pure block parameter ("The push says what the element holds, not what the element is"); the path for two or more parameters now makes it too.

Of the 444 programs that segfaulted (120) or did not build (324), 327 are now right, 45 raise as above, and the other 72 answer as master answers once another line types the receiver. That is reached here, not made: each of the 147 programs this changes to anything but right prints, byte for byte, what master prints for it with `h[:a]` added as a last line, and compiles to that program's C less the added line's.

- 60 (24 segfaults, 36 no builds) lose the append to a String value: `v << x`, `v << "!"` and `v.push(x)` in `each`, `each_pair`, `map`, `select` and `reject`. That is the documented limit, "A plain String in a slot that holds other values too is not shared by `<<`"; this adds no sharing route. A boxed parameter's `push` is compiled as its `<<`, so the 24 of them that send `push` to a String are silent where CRuby raises NoMethodError.
- 12 (6 segfaults, 6 no builds) send `push` to an Integer value and raise TypeError where CRuby raises NoMethodError, for the same reason.

Under `--share-strings` nothing changes and the crash stands: a push onto the boxed `v` does not build there yet. All 1,296 compile to master's C under the flag or are refused by both.

Counts are on master 8684d54ce, the same with gcc and clang and in both overflow modes. In the corpus only the new test's C differs, in both overflow modes; under `--share-strings` none does.

## `make gate` (on this branch merged with current master)

```
not run yet: this branch waits for the full gate
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
