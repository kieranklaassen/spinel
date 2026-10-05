## What this changes

```ruby
k = ARGV.size + 16
s0 = +"0"; s1 = +"1"    # ... one for each arm, to s17 = +"17"
t = case k
    when 0 then s0
    when 1 then s1
    # ... seventeen `when`s in all
    when 16 then s16
    else s17
    end
t << "x"
p s16, t.equal?(s16)    # CRuby: "16x" and true. Spinel: "16" and false
```

A write whose value is a conditional over String locals hands its target the String of the arm taken (#6617). The walk that pairs each arm's local with the target (`an_strbuf_alias_leaves`) wrote into an array of sixteen its callers held. A local read only by the seventeenth or a later arm was left off, so that arm handed over a copy and a change made through the new name never reached the String. The list now grows with the arms; the callers keep one across their loop and free it. Which Strings are shared is decided as before, and nothing that built is refused.

**Checked** on master c2dadf497 (the two generated sets on master 5c2dea515), gcc and clang, against CRuby 3.3.6 run with `--enable-frozen-string-literal`.

- `test/string_alias_conditional_many_arms.rb` takes each of eighteen arms once: appended to, handed to a method that appends, replaced in place, and at the top level with a frozen String in an arm. Master prints 10 of its 76 lines wrong. It passes under `SPINEL_GC_STRESS=1` and `2`.
- `make cident REF=upstream/master`: `6129 identical, 1 differ, 0 refusal changes`; the program that differs is the new test.
- A generated probe of 8,064 programs (14 conditional shapes at nesting 1 to 17, every arm taken, followed by `<<`, `replace`, `gsub!` or a method that appends): 20 compile to different C, the ones with seventeen arms of locals. Master is right on 1 of them and the branch on all 20.
- 15,669 programs that call on the conditional itself (`t = (c ? a : b) << "1"`, chains of two and three calls, an eighteen-arm `case` as the receiver): 192 compile to different C. No program right on master is wrong on the branch.

**Left alone**, as on master:

- An arm past the eighth level of nesting is nil or a copy: the last of three chained ternaries, an `if` in an `else` in an `else`. The eighteenth arm of the chain below is one, and still raises.
- The value of a call on a conditional receiver is a copy, whatever the number of arms, and `replace` followed by another call loses that call from the receiver:

  ```ruby
  t = (case k when 0 then s0 ... when 16 then s16 else s17 end).replace("r") << "1"
  p t, s0, s16    # CRuby, k = 0: "r1" "r1" "16"; k = 16: "r1" "0" "r1"
  ```

  Master prints `"r1"` `"r"` `"16"` for k = 0 and raises a FrozenError, which CRuby does not raise, for k = 16. With the seventeenth arm on the list, k = 16 prints `"r1"` `"0"` `"r"`: the first arm's answer. The programs of this shape change this way: `replace` followed by a second call that changes its receiver (`<<`, `insert`, `replace`, `concat`, `prepend`, `clear`), with the seventeenth arm taken, as a write's value (`t =`) or written back to the first arm's local (`s0 =`). Each line they print wrong is a line master prints for the same program taking its first arm, or with the conditional replaced by the local it takes.

## `make gate` (on this branch merged with current master)

```
not run here: the full gate waits for the Mac. Legs run one by one in the cloud:
infer-test, reject-test, collect-errors-test, traits-check-test, bop-arity-check-test, diff-test,
spin-check, scale-test (1.71 / 4.73 / 6.06 / 4.22) and cident pass.
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints Integers, booleans and one class name)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here)
- [ ] Depends on: #
