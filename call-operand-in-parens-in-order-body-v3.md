<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A call whose later operand is written in parentheses runs that operand's nil check ahead of the operand before it:

```ruby
class Box
  def val = 7
end
$o = nil
def mk = ($o = Box.new; "t")
p mk.length + ($o.val > 9 ? 1 : 2)
```

```
spinel diff: exception-diff
  program: order.rb
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'val' for nil

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-3
```

`emit_operands_in_order` binds a call's operands in Ruby's order when each one that runs code is a call or a conditional, and it asked the kind of the operand as written. In parentheses that is a ParenthesesNode, so the whole call was left to C's order, and what the parenthesized operand hoists (the nil check of `$o`, an Array literal, the leading statements of an `if` arm) ran in the statement's prelude, ahead of `mk`. `p mk * (late)` ran `late` first under gcc. The kind is now asked through the parentheses, so the call compiles as `mk.length + $o.val` does.

Not where an operand before the last may be a String in a program that changes a String in place: CRuby reads the String when the call runs, so `k.name * (k.rename)` shows the rename, which a String bound first misses. Those calls compile as they did: master answers them right with gcc, whose arguments run right to left. Whether the program changes a String is scanned once, before any code is emitted: the statement arm of `gsub!`, `sub!`, `tr!` and `delete!` renames its node to the plain form while it emits it, and a scan first asked for from there read `gsub`. No line of the test can hold this, because the declined call answers in C's order, which gcc and clang do not share: it is held by C identity, 999 programs that change a String in place by 111 routes compile to master's C byte for byte.

A computed operand written before the one in parentheses, `nums.slice($i + 1, (bump))`, is no effect of its own and is not bound here: the pull request this one depends on reads it in order. Without that one this change would turn the call's whole decline into a rewrite around the computed read.

Cost: an operand in parentheses that runs code costs what it does without them. With Integer operands that is nothing (callgrind, a million `bump - (bump * 2)`: 27,349,971 before and after). Two String calls, `name + (tail)`, cost 30 instructions a call more (499,609,025 to 529,615,409), the rooting `name + tail` has on master.

Not here: a Range, a literal, a write or a sequence in parentheses is not bound, so `mk.length.clamp((late - 2)..(late + 5))` runs `late` first under gcc, as on master.

Test: `test/call_operand_in_parens_in_order.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (five calls now bind their operands: 2,378,018,205 instructions before, 2,378,018,231 after, checksum 59662)
- [ ] Depends on: the pull request "A computed operand is read in the order written"
