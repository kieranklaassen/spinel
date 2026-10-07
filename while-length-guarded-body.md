## What this changes

```ruby
def scan(s)
  i = 0
  while s && i < s.length
    i += 1
  end
  i
end
p scan("abc")
p scan(nil)
```

printed `3` and then raised `undefined method 'length' for nil (NoMethodError)`. CRuby prints `3` and `0`.

```
spinel diff: exception-diff
  program: guard.rb
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'length' for nil

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1 @@
 3
-0
```

`emit_while` reads a String local's length once ahead of the loop, and it took that read from anywhere in the test, so the read was made where the guard keeps Ruby from it. The same behind `!s.nil? &&`, `until s.nil? ||`, a ternary, an `if` modifier, `&.` and a flag. A read on the right of `||`, or after an operand with an effect (`(i += 1) < s.length`), raised ahead of the passes and the effect Ruby runs first.

The length is now read ahead only when the first test reads it before anything else: down the receivers, past operands that are plain reads, and on the left of `&&` and `||`. Any other loop reads the length in its test, as a loop with nothing to hoist does.

Checked: `test/while_length_guarded.rb` raises on master and is right on the branch with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2. `make cident REF=2f204adb`: 6,339 identical, 1 differ (the new test); optcarrot's C is identical.

Left alone: `while i < s.length && ...` and `while i + 1 < s.size` keep their C. `s.respond_to?(:length) && i < s.length` still raises for a nil `s`: `respond_to?` answers true for a nil typed String, with the read hoisted or not.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`while_length_guarded` is written from CRuby 3.3.6; its 4.0 run is owed)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: # (nothing)
