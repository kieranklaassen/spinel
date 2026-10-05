<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

```ruby
def twice
  r = []
  r << (yield 1)
  r << (yield 2)
  r
end
p twice { |x| next 1.5 if x == 2; 2.5 }   # [2.0, 1.0]; CRuby prints [2.5, 1.5]
```

After: `[2.5, 1.5]`.

A block that holds a `next` and answers a Float lost the fraction of what it handed to the yield, from the `next` and from its last expression alike. The fraction is kept now in two cases. The block cannot leave with nil: its last expression and the value of each `next` are a number literal, arithmetic on numbers, `to_f` of an Integer, or a conditional with an `else` made of these. Or the method keeps the yield's value boxed, which it does where blocks of two kinds reach it or the block comes through a `super`:

```ruby
def one
  v = yield 2
  v.nil?
end
p one { |x| next if x == 2; 2.5 }   # false before; true now, as CRuby
p one { |x| x * 2 }
```

There a bare `next` and a `next nil` answer nil as well, where they answered a Float. The call can be an ordinary one, a `super`, or `b.call` on a block parameter.

How: `emit_block_invoke` declares a slot for the value of a block that holds a `next`. The declaration had no arm for a Float, which fell to the `sp_int` arm kept for a value with no type, while the `next` already stores into the slot as a Float one (`g_ie_next_ty`). In the two cases above the slot is now an `sp_float` that starts as `sp_float_nil()`, as Array.new's is, and where the value is boxed `emit_boxed` boxes it with `sp_box_float_or_nil`.

Left as on master, with the same C: a block that can leave with nil (a bare `next`, a `next nil`, a value that is a local, an instance variable, an element or a call) where the yield's value is read as an unboxed Float. `p twice { |x| next if x == 2; 2.5 }` alone still prints `[2.0, -9.223372036854776e+18]` for `[2.5, nil]`, `one` above with its first call alone still answers false, and filter_map over such a block keeps the dropped element as that number. A Float slot would hold the nil as the Float sentinel, and `to_f` and `to_i` on an unboxed Float do not look for it: `v = yield 2; v.to_f + 1` under `{ |x| next nil if x == 2; 2.5 }` prints 1.0 today, as CRuby does, and would print nil from a Float slot. Master is right there by a conversion C leaves undefined (the sentinel stored into the Integer slot, which gcc makes 0): under clang 18 the sibling `s += (yield i).to_f` prints 6.0 for 4.0 on master, and does with this change too.

Generated C against master 23e9734d (`tools/cident.sh`): 6,103 programs identical, 1 differs (the new test), no refusal changes. optcarrot's C is identical.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
