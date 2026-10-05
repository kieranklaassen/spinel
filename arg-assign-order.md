<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
def f(a, b) = [a, b]
f(1, "s")                         # the second parameter is boxed
n = 3
p f((n = 5; 1), n)                # [1, 5] in CRuby, [1, 3] here
t = "a"
p "x".rjust((t = "b"; 5), t)      # "bbbbx" in CRuby, "aaaax" here
```

Before: an argument that assigns a local and a later argument that reads it stood side by side in one C argument list. C leaves that order open, gcc ran the later one first, and the call bound the old value with nothing said. It went wrong through a method, a class method, `K.new`, a Struct's and a Data's `new`, keywords, an optional, a rest, `yield` and `super`, and through a builtin over plain values (`rjust`, `gsub`, `tr`, `"s"[a, b]`, `Integer(s, base)`, `pow`, `clamp`, `Array#insert`, `dig`). clang ran these left to right and still bound the old value where the later argument is built ahead of the whole call (`[n]`, an interpolation).

After: a call whose earlier argument assigns a local that a later argument of the same call reads binds the new value, as CRuby does. The assignment still runs at the call's own place: a read to the left of the call in the same statement sees the old value, and a call that a test in front of it skips assigns nothing. Two receivers that master builds ahead of their statement are the exception; they are under "Not in this change".

How: a read that a later argument can rebind is taken into a temp already (`read_rebound_by`). This is the other direction. `later_read_rebound_by` asks whether an argument assigns a local that a later one reads or, for a call of the program's own, may call a proc that assigns it. `args_order_matters` and `emit_args_before_binding` count such a pair, so the values run first, in order, into temps the call reads. Those temps do not go into the statement's prelude, where the calls with two effectful arguments put theirs: the emitter of the call, the `yield` or the `super` cuts what its emission added there back out and writes it in front of the call's own text, in one statement expression (`args_in_place_begin`, `args_in_place_end`), as `emit_constructor` keeps its own. For a builtin, `emit_operands_in_order` binds an operand that assigns a local a later operand reads even when it is the only observable one, with what the arm built ahead of the call for the other operands placed behind the binding, and `emit_operands_before_unbound` runs the operands up to it first where the rewrite cannot bind one.

Measured with gcc 13.3 and clang, CRuby 3.3.6 with `--enable-frozen-string-literal` as the reference. The test and the generated C are measured on master MASTER_AT_OPENING; the two program sets were run on master 1be84842, which has #7358.

- `test/arg_assigns_local_later_arg_reads.rb`, 105 lines. On master with gcc it prints 60 lines, 45 of them wrong, and then raises ArgumentError; with clang 6 of the 105 are wrong. Here it prints its `.expected` with gcc at `-O0` to `-O3`, with clang, and under `SPINEL_GC_STRESS=1` and `2`.
- 2,188 generated shapes (how the argument assigns, how the later one reads, what takes the call), each its own program: 343 that are wrong on master are right, none that is right on master is wrong. 11 differ from the 3.3.6 reference only in how a Hash prints, and 8 do not parse, under CRuby either.
- 989 hand-written programs, each run on its own and compared line by line (reads to the left of the call, tests in front of it, heap values, `yield`, `super`, loops, `rescue`, identity and control flow): with gcc 427 lines wrong on master are right and none right on master is wrong; with clang (on master 50734d56) 72 and none. Under `SPINEL_GC_STRESS=1` and `2` the same, but for two programs that reach a freed String under stress 2 on master as well.
- `tools/operand_probe.rb` on the new test without its last line (a String handed through the probe's own method is a copy): 109 calls, 248 operands, no finding.

**Generated C.** `make cident REF=origin/master`: `CIDENT_LINE`. What differs is the new test and two programs of the corpus: `test/proc_rebound_local_arg_order.rb` (a keyword call whose first value may call a proc assigning the local the second reads: the temp master already made now stands at the call) and `test/interp_statements_run_in_place.rb` (the receiver of a `+` assigns `_cap`, which the argument reads after an assignment of its own, so the receiver goes into a rooted temp: one temp more, the same answer). Each prints its `.expected`, also under `SPINEL_GC_STRESS=1`. optcarrot's generated C is byte-identical.

**Cost.** Where no argument assigns a local that a later one reads, the C is the same, so nothing. Where one does:

| loop | master | here |
|---|---|---|
| 300 million `g((n = i; 1), n)`, plain Integers | 0.193 s | 0.175 s |
| 100 million `f((n = i; 1), n)`, boxed | 0.126 s, wrong answer | 0.099 s |
| 30 million `"ab".tr((t = "a"; "b"), t)` | 1.88 s | 1.82 s |

Best of six each. Under callgrind the builtin form costs nine instructions a call more (one rooted temp) and a call of the program's own nothing.

Compile time: the four `make scale-test` ratios are master's; they are with the gate lines below.

No function over 1,000 lines is touched: `emit_operands_in_order` is 224 lines, `emit_call` 164. `emit_call_body` is not touched.

Not in this change, wrong on master and unchanged:

- An instance or a global variable written by an earlier argument: `f(bump, @v)`, `f(($g = 5; 1), $g)`.
- A builtin's operand that calls a proc assigning the local: `2.pow(la.call, n + 0)`. Through a method of the program it is right now.
- A later argument that `p` or `puts` builds ahead of itself: `p((n = 5; 1), [n])`.
- An index assignment: `h[(n = 2; 1)] = n`, and `h.store((n = 5; 9), n + 0)` as a statement.
- A receiver that assigns, appended to: `(n = 5; k).s << n.to_s`.
- A later operand that is a literal or an interpolation with a call inside: `(s = "abc").upcase.sub("A", "#{s.size}")`, `(a = [1, 2]).dup + [a.size]`.
- A read to the left of the call that master already runs late: a Range's first bound in `(n..f((n = 5; 1), n))`, the index in `h[n] = f((n = 5; 1), n)`.
- A constructor that is itself a call's receiver still runs ahead of its statement: `"#{n} #{K.new((n = 5; 1), n).show}"` reads 5 to its left, and behind `$g ||=` with `$g` set it still assigns `n`.
- An Array literal that is the receiver, the same: `[(n = 5)].dup.concat([n])` with a read to its left, or in a later `when`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: #SAFE_NAV_PR (a `&.` call on a nil receiver runs none of its arguments; without it one line of the test, a `&.` call on a nil receiver, is wrong)
