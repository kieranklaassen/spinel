<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`recv.x = value` as a statement, through a generated writer (`attr_writer`, `attr_accessor`, a Struct member), did not hold its receiver while the value ran. Two faults came of it.

The cure has a price, and it is the root that holds the receiver: a store whose receiver is a call's answer and whose value allocates, `pick(k).v = "s" + i.to_s`, costs 15 instructions more (481 to 496 a store by callgrind, 200,000 stores in a loop). A store whose value does not allocate, or whose receiver is a plain read, costs what it did.

A receiver nothing else holds was collected by a value that allocates, and the store wrote into whatever had taken its place. In a plain run:

```ruby
class K
  attr_accessor :v
  def initialize(v) = @v = v
end
bad = 0
20_000.times do |r|
  K.new("v").v = (made = Array.new(8) { |i| K.new("k#{i}") }; r)
  bad += 1 unless made.all? { |k| k.v.is_a?(String) }
end
p bad        # CRuby 0, spinel 1
```

Once in the 20,000 rounds the Integer lands in one of the eight objects the value has just made; with `SPINEL_GC_STRESS=1` it does so 5,467 times. With `SPINEL_GC_STRESS=2` the store's write barrier records the freed object and the run stops:

```ruby
class Account
  attr_accessor :note
  def initialize(name)
    @name = name
    @tags = [name]
  end
end
def fresh(name) = Account.new(name + "!")
def churn
  a = []
  40.times { |i| a << ("s" + i.to_s) * 3 }
  a
end
keep = []
fresh("f").note = churn.last
keep << churn.last
p keep
```

```
*** SPINEL_GC_VERIFY: fault on the GC mark path (signal 11)
  phase = remembered
```

And the value could run before the receiver. Where the slot needs no barrier the store is one C assignment, `(sp_account(lv_a))->iv_balance = sp_int_add(sp_amount(), 1LL)`, and the C compiler orders its two sides; what a value hoists (a block's loop) ran ahead of the whole statement:

```ruby
class Account
  attr_accessor :balance
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
account(a).balance = amount + 1
p a.balance
```

```
spinel diff: output-diff
  program: order.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-account
 amount
+account
 101
```

Where neither the receiver nor the value is a plain read (`subtree_is_pure_read`; a global receiver counts as one), the receiver now goes into a temporary declared ahead of what the value hoists, rooted while a value that may allocate runs. Every other store keeps its C.

2,400 programs that trace what runs (the writer in the class, in a superclass, in a module, a Struct member, a slot of two types, a class whose freeze is observed; fifteen receivers; ten values; as a statement, a value, an argument and in a loop): 71 were wrong and are right, 1,623 have master's C, 694 are right on both with the receiver now held. 120 more with a class that holds an Array, at `SPINEL_GC_STRESS=2`: 4 fault on master and 6 run the value first; all are right here.

**Not in this change.**

- The value form, `x = (recv.v = value)`. Its store takes the write barrier before the value runs (`SP_WBO(_t)->iv_v = value`), a fault of its own, and holding the receiver there would only lead the collector into it. 12 of the 2,400, whose value hoists a loop past a receiver that is no call (`x = ((b = recv(a)).v = [1, 2].map { ... })`), stay wrong with master's C.
- A receiver that is a plain read and that the value changes: `c.v = (c = b; val)` stores into `b`, where CRuby stores into the old `c`.
- A receiver read out of an Array, or out of a Hash written as a literal, that the value empties: `a[0].v = (a.clear; made = build; r)`, the same through `a.last` and `a.pop`, and through `h[:k]` and `h.delete(:k)` where `h = { k: K.new("v") }`. Such a receiver is a boxed value and its store takes another arm, which this change leaves as it is, with master's C: the first of them stores into an object the value has just made in 9 of 5,000 rounds of a plain run. A Hash filled by assignment (`h = {}; h[:k] = K.new("v")`) holds its values as the class: its receiver takes this arm and is held.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
