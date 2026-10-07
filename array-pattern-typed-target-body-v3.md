<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
t = "o"
case [3, "s"]
in [Integer => t, String]
  p t        # 3
end
```

Before: exit 139, nothing printed. With `n = 0` bound by `[String => n, Integer]` over `["a", 4]`, `p n` printed 0. `t = "o"` bound by `[*, t]` over `[1, 2]` did not build.

After: 3, "a" and 2.

Cost: such a local is boxed, and only where every other use of it prints or compares it, so what is left to pay is a boxed comparison. Ten million `t == "o"` on a run where the arm does not match take 0.099 s where they took 0.007 (a Symbol 0.058 for 0.005, a Float 0.066 for 0.005, an Integer 0.009 for 0.005, `nil?` the same). No program that was right changes its answer in the families below.

A binding converts the boxed element to the local's type (`emit_pm_typed_assign`), and `infer_case_pattern_locals` unified that type with the element only for a bare required target (`[t, String]`). A captured element, an element after the splat and the targets of a nested pattern kept the type the local's assignment gave it, so an Integer was unboxed as a String.

Chosen: the local is boxed, in an Array pattern and in a find pattern's window, where both hold.

1. The element is surely of another class. Every assignment to the local is a statement `x = literal`, and
   - the capture names `Integer`, `Float`, `String`, `Symbol`, `NilClass`, `Array` or `Hash`, a literal of one, an Array pattern, or alternatives of those, and no assignment writes a literal of that class; or
   - the subject is an Array of Integers, of Floats or of Strings, the literals are of another class and none is `nil`.
2. Every other use of the local is on a list (`pm_uses`) of what a boxed local answers as the typed one did:
   - `puts x`, `print x`, a statement `p x`, and its interpolation;
   - `==` and `!=` with a literal, and `nil?`;
   - printed by `puts` or a statement `p`, or interpolated, at once: `class`, `inspect`, `to_s`, `+` and `-` with an Integer literal, `size`, `length`, `empty?`, `upcase`, `reverse`, `first`, `to_sym`, `to_f`.

So the boxed value is printed or compared and goes nowhere: not into a container, an object, an argument, a block's or a method's answer. A local with any other use, and every other local, is typed as it was and writes the same C.

Rejected: boxing wherever the class differs, whatever the uses. It cures more, but a boxed String stored into a container or an object is a copy (`Box.new(t).v << "m"` no longer reached `t`), a boxed value answers `object_id` and `equal?` otherwise and has no `upto`, and programs that were right went wrong or were refused.

Not here, and unchanged:

- a bare target after the splat over an Array whose element class is not typed (Symbols, `true` and `false`, `nil`, Arrays, Hashes, objects, Ranges, a mix): `t = "o"` bound by `[_, *, t]` over `[:q, :r]` still exits 139;
- the capture of an arm that then fails, which Ruby keeps: `[Integer => t, String]` over `[3, :w]` leaves `t` as it was, where Ruby prints 3.

Measured:

- The list was drawn on master, on a local it boxes already (two assignments that never run): 5,616 generated programs, each listed use by each way of printing it by up to 21 kinds of value, and from a method, a block, a lambda, a loop and a rescue. They print what CRuby 3.3.6 prints, but for 64 that differ only in the 3.3 format of `Hash#inspect` and 27 where the call raises as in Ruby and master skips the `ensure` of a `begin` whose `rescue` names another class, as it does for any exception. Two uses failed there and are off the list: `print x.class` (refused) and a literal's own `==` with an object of the program's own class.
- The cure: four generated families (a capture, a bare target after the splat, twelve kinds of body, and the 457 programs of this fix's earlier form), 9,090 programs, of which 3,978 change. 1,224 were right and stay right, 2,493 become right, and 261 fail as before for another cause (249 where a lambda reads the local do not build, 12 are a RangeError). A sample of 461 was also run with clang, with `--int-overflow=promote` and at `SPINEL_GC_STRESS=1` and `2`: 458 right each way, 3 as on master (a bignum element).
- Off the list: 50,946 programs with one more use after each shape of pattern. Where that use is off the list the C is master's byte for byte.
- Counted on master 8684d54ce75f; every program of these families writes the same C on 26d456ec1035, on master and with the change.
- `make cident REF=26d456ec1035`: `6351 identical, 0 differ, 1 refusal changes, 0 refused by both, 0 not in the reference`; the one refusal change is the new test, which master refuses.
- `test/array_pattern_target_typed_before.rb`: master refuses it (`undefined method '-' for an instance of String`, for a local it typed a String). With the change it prints its `.expected` with gcc and clang, with `--int-overflow=promote`, and under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
