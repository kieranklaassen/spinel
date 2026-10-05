<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class R                                  # reads tokens off a queue
  def initialize(t) = @t = t
  def nxt = @t.shift
  def item(tok) = tok == "(" ? "[" + item(nxt) + "]".tap { nxt } : tok
end
r = R.new(%w[( a ) b])
puts "#{r.item(r.nxt)} #{r.item(r.nxt)}"   # "[a] b" in Ruby, "[)] a" here
```

The parts of an interpolation run out of order. In `"#{a.f(x1)} #{b.g(x2)}"` both arguments run first, then `f`, then `g`; CRuby runs x1, `f`, x2, `g`. So a later part's argument does not see what an earlier part's call did: above, the second `r.nxt` takes its token before the first `item` has read on. `"#{k.bump} #{k.f(k.cur)}"` passes the old `k.cur`, and `"#{n += 1} #{k.two(n, lg(9)).name}"` the old `n`. The String that is built from the values is put together in order; it is the calls that are not. With gcc and with clang alike.

After: each part runs to its end before the next part's arguments start, where the interpolation is a statement's value, an assigned or returned value, a condition's arm, an argument beside plain reads, or is appended with `<<` (the rest is under "Not here").

How: `interp_plan` (`src/codegen_expr.c`) evaluates each part's value in its place, inside the statement expression that builds the String. What a part's call hoists (the operands `emit_operands_in_order` binds to temps, a receiver's temp) went to the statement's prelude, ahead of every part. Now, once an earlier part has an effect (`subtree_has_side_effect`), the hoists of a later part are kept in that part's place if its operands hold a call or an assignment, or read a variable an earlier part gives another value (`read_rebound_by`).

Where: in the prelude the hoists ran before everything the statement evaluates; in the part's place they run after whatever stands before the interpolation in the same C expression, in the order the C compiler picks. `"#{k.name}#{k.two((n += 1), lg(1))}".center(n + 12, "*")` is right on master and would read `n` too early with gcc. So they move only where the interpolation is sequenced against the rest of its statement (`interp_sequenced`): from the interpolation up to the body it is written in, each node evaluates its children in order (a statement, parentheses, a conditional, `&&`, `||`, a loop, a variable's assignment, another interpolation), or its other operands see nothing the interpolation can change: a literal, self, a constant, a variable no part assigns and whose value is not changed in place, arithmetic over those, a block. `buf << "..."` as a statement appends part by part and is sequenced. Anywhere else the C is master's, byte for byte.

`test/interpolation_parts_run_in_order.rb` prints 21 lines: one call a part, three parts, a chain in each part, literal arguments, a later part reading what an earlier one changed, the token reader, `<<`, in a method, in a block. On master 9 of them are wrong, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`; here it prints its `.expected` in all six.

Generated C against master (`make cident REF=9c4eec71e`): 6101 identical, 35 differ, 0 refusal changes. The 35 are the new test and 34 programs: one line of `packages/ffi/ffi.rb`, ``key = "#{ret.object_id}:#{nfixed}:#{types.map(&:object_id).join(",")}"``, compiled into 13 ffi tests, 8 fiddle tests and `test/ffi_gem_compat.rb`; `packages/net/test/net_http_header_crlf.rb`; and 11 tests under `test/`. In each a later part's temps stand in its place. Each prints on this branch what it prints on master, with gcc and with clang, at the three levels (25 their `.expected` in all six; 9 stop under `SPINEL_GC_STRESS=2` on master and here alike). optcarrot's generated C is byte-identical.

A matrix of 936 programs, measured on c2dadf497: 39 pairs and triples of parts (calls with one and two arguments, chains, a part that assigns `n` or appends to a String, a conditional, `&&`) in 24 places, each built with gcc and with clang and run plain and under `SPINEL_GC_STRESS=1` and `2`. Master prints CRuby's answer in all six for 279. Here 585 do: all 39 as an assigned value, under `puts`, as the one argument of a call, appended with `<<`, returned, in a block, in a conditional's arm, nested in another interpolation and in a loop, and 36 of 39 beside a read of `n` (the three whose parts assign `n` stay). None loses a cell. Of the other 351, 312 have master's C and master's answer, and 39 are an interpolated Symbol (both under "Not here").

Cost: none where no part moves, the C is master's. Where one moves, the same temps stand in another place:

```ruby
class K
  def f(a) = a * 2
  def g(a) = a + 1
end
def id(x) = x
k = K.new
n = 0
i = 0
while i < 200_000
  s = "#{k.f(id(i))} #{k.g(id(i))}"
  n += s.size
  i += 1
end
p n
```

83,024,271 instructions on master and 83,024,285 here (callgrind).

Not here, wrong on master and not made right:

- An interpolation that is an operand beside a call, an element or a field read, a String or boxed variable, or a variable one of its parts assigns keeps master's order: `pair("#{k.f(lg(1))} #{k.g(lg(2))}", lg(91))`, `[lg(94), "...", lg(95)]`, `"..." + lg(92).to_s`, `"..." == x.to_s`, as a Hash literal's value beside another. The 312 above.
- An interpolated Symbol, `:"#{k.f(lg(1))}/#{k.g(lg(2))}"`, runs in order here (27 of the 39 did not on master) and prints bytes that are not its name under `SPINEL_GC_STRESS=2`, as on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
