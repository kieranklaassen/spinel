<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A refusal with a cost, which is yours to weigh: of 1,062 programs measured, 124 are right on master and refused here. In each a String held by an instance variable, a global, a class variable, a parameter, a block's parameter or a captured local is handed to such a method and never read afterwards. The same 124 programs with one more line, a read of that variable after the call, are among the 180 that print a wrong answer on master.

```ruby
def countdown(out, n)
  out << n.to_s
  if n > 0
    countdown(out, n - 1) { |v| yield v }
  else
    yield out.size
  end
end
buf = +""
r = countdown(buf, 3) { |v| v * 2 }
p r, buf     # 8 and "3210" in CRuby, 8 and "" on master
```

A yielding method is spliced into its call, where its parameters name the caller's Strings. One that calls itself with a block that yields, keeps its `&blk` as a value beside a `yield`, or yields inside a `Thread`'s body is compiled as a function instead, and no yielding method takes a lent slot (`an_byref_eligible_scopes`). Its String parameter is then the caller's text by value, and what the method appends goes to a String of its own, with nothing said. With `--share-strings` the first two kinds do the same; the Thread's parameter is the shared handle there and is right.

What was chosen: CONTRIBUTING asks that a route that silently copies a String a callee appends to be refused at compile time and that no per-route sharing rule be added. So the call is refused by name with `refuse_string_copy`, as the other routes that would copy are, where a String variable is handed to a parameter such a method appends to:

```
a String is passed to `countdown`'s parameter `out` through the call, which the method appends to: this call hands the method a copy, so the append would not reach the caller's String (a String is not yet shared by reference into a yielding method that is compiled as a function). Return the String from the method and assign it, or append to it in the caller.
```

Two calls cannot observe the copy and compile as before, with master's C: a plain local that is read nowhere else and stands in no loop or block (the rule `Thread.new`'s argument has), and the method's own appended parameter handed on by its last call with a block that does not read it, since its callers are asked at their own calls. A literal or any other expression is never refused, and a parameter the method assigns again is left alone.

Not in this change, wrong on master and the same here:

- a constant as the argument is a copy for every method that appends to it, yielding or not (46 of the programs, without the flag);
- under `--share-strings`, a method that reads its parameter after its call of itself, or in that call's block, once the String has outgrown its buffer: the share facts take the route for followed, so it is not refused there (`s << "abc...z"` at nine levels prints 3556 for 5220). Without the flag it is refused.

Tests: `test/reject/string_yielder_calls_itself_param.rb` is the program above, `string_yielder_kept_block_param.rb` a method that keeps its block in an Array beside a `yield`, `string_yielder_thread_param.rb` one that yields inside `Thread.new`. The three are in the list of an existing `reject-test` loop, with six records in `test/collect/refusals.expected`; the third compiles right under the flag and is in `test/share/reject.list` with its output there. `test/yielder_function_string_param.rb` holds what stays: a literal, a local read nowhere else, a parameter the method only reads, an Array, a spliced yielder, and a class method and an instance method handed a literal. It is right on master and here.

Generated C against master (`make cident REF=759d120f`): `6430 identical, 0 differ, 0 refusal changes` (the new test's C is master's). `tools/refusals.sh` passes (540 records); `make reject-test` and `make share-strings-test` pass. optcarrot's generated C is byte-identical. Programs of ours, on master 759d120f with CRuby 3.3.6 as the reference: 1,062 calls of a method that takes a String and a depth. Eight kinds of method: four compiled as functions (calls itself with a block that yields, calls itself handing on `&b`, keeps `&b` as a value, yields in a Thread) and four controls (a spliced yielder, a `b.call` method, a method with no block, one that calls itself with no block). Six bodies (`<<`, `concat`, `upcase!`, `replace`, handing the String to a method that appends, only reading); ten arguments (a local, an instance variable, a global, a class variable, a parameter, a block's parameter, a captured local, a literal, a reader call, a constant); the variable read after the call, read in the call's block, or not read; a top-level method, an instance method and a class method.

| | without the flag | with `--share-strings` |
|---|---|---|
| wrong on master, refused | 180 | 135 |
| right on master, refused (the cost) | 124 | 93 |
| the same, right | 712 | 834 |
| the same, wrong | 46 | 0 |

Every program in the last two rows has master's C byte for byte (758 and 834).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers, Strings and an Array)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
