<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`recv.x = value` through a hand-written `def x=` ran the value before the receiver, when the value is more than a literal or a variable:

```ruby
class Account
  attr_reader :balance
  def balance=(b)
    @balance = b
  end
end
def account(a)
  puts "account"
  a
end
def amount
  puts "amount"
  100
end
a = Account.new
account(a).balance = amount
p a.balance
```

```
spinel diff: output-diff
  program: acct.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-account
 amount
+account
 100
```

The assignment's value is its right-hand side, not what the writer returns, so the call binds the value to a temporary and reads it back after the writer. That temporary was declared ahead of everything the call's own emission hoists, the receiver among them. A receiver that is more than a read (`subtree_is_pure_read`) is now held in a temporary of its own ahead of the value's, and the call reads it there. It is rooted while a value that may allocate runs: a receiver nothing else holds would be collected (`pad("f").note = churn.last` in the test; a fault at `SPINEL_GC_STRESS=2` without the root). A receiver that is a plain read keeps its C.

3,320 programs that trace what runs (a writer written by hand in the class, in a superclass or in a module, or a generated one; fourteen receivers; ten values; as a statement, a value, an argument and in a loop). Through a hand-written writer 1,080 were wrong and are right, 1,032 have master's C, and 648 are right on both with the receiver now held (its call leaves no trace: `arr.first`, a reader written by hand). Through `attr_writer` all 560 have master's C.

The cost of holding it, callgrind, 200,000 calls of `def set(a, i); pick(a).v = V; nil; end`: none for `i + 1`, whose receiver needs no root (6,064,579 instructions with and without); 4 instructions a call, 526 to 530, for `"s" + i.to_s`, whose receiver is rooted while the String is built.

**Not in this change.**

- A local receiver that the value assigns: `c.v = (c = b; val)` stores into `b`, where CRuby stores into the old `c`.
- `attr_writer`: `recv(a).v = val + 1` runs `val` first, in 34 of those 560. The store there is one C assignment, `(sp_recv(lv_a))->iv_v = sp_int_add(sp_val(), 1LL)`, and the C compiler orders its two sides. The pull request "An attribute writer statement holds its receiver while its value runs" is for that store: with it 30 of the 34 are right, and the other 4 are the value form it names.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
