<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`z = [c.plus]; z[0] << "z"` with `def plus = @x + "a"` did not build with clang and ended in SIGSEGV with gcc, and so did `z << c.to_s` and `h[:k] = c.show`, wherever the container's Strings are changed in place. The method's plain String went into the box under the shared handle's tag.

A method whose body is seen to build a new String (it ends in an interpolated String, in `to_s`, `inspect` or `chr` of an Integer or a Float, or in one of 34 String methods that always answer a new one) is now wrapped as a fresh handle where it is stored, as a call on a String already is. A nil it answers (`def up = @x&.upcase`) is stored as nil.

Every other call on an object is read as before, which means its store still does not build with clang and still ends in SIGSEGV with gcc: a reader, a method that may answer a String the object holds (`@f ? @a : @b`, `@x.itself`, and `@x.clone`, which a program may define), one not seen to be new (`@parts.join`), a name one class gives both a def and an attr reader, and a method a subclass overrides with one that is not seen to build its String, on an object of the parent class too.

Not cured here: where a second String goes into the same container as a copy, the append to that one is still lost. A program that stopped at the first store now runs on and prints what it prints today with a plain String in the call's place (`z << "qa".dup << s; z[1] << "?"`). The copy is a String handed to `concat`, `insert`, `prepend`, `merge!`, `update`, `+=` or `||=`, a splat, or a later link of a push chain, in the same statement or another, through an alias of the container, a method or a block.

A no-op `sub`, `center`, `ljust`, `rjust` or `encode` answers its receiver itself in the runtime, so over a frozen literal (`def m = @x.center(1)`) the append now raises FrozenError where it crashed and CRuby appends.

Nothing is refused that was not, and no String is shared that was not.

Measured on master c6bbdfbc9 merged with this branch (gcc 13.3, `SPINEL_GC_STRESS` unset, 1 and 2, against CRuby 3.3.6 with `--enable-frozen-string-literal`), over 1,300 programs written to break it: 344 that crashed (one raised) now print CRuby's output, the 194 that were right stay right, 7 go from the crash to the FrozenError above, and 70 go from the crash to the lost append above. The other 685 do on this branch what they do on master: 483 crash, 150 print the same wrong line, 31 are refused, 13 do not build, 7 raise, and one runs right and aborts at `SPINEL_GC_STRESS=2`. Each of the 70 prints byte for byte what master prints for the same program with a plain String in the call's place, and its generated C differs from master's only in the wrapped call. The new test passes with gcc and with clang 18 at -O0 to -O3. `make cident`: 6057 identical, 1 differ (the new test), 0 refusal changes; `tools/refusals.sh`: 426 records on both.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # 
