<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
title = +"abcd"
label = title.upcase!
label << " and a tail long enough to move the buffer"
p title
```

Before: `"ABCD"`, and `label.equal?(title)` is false. CRuby prints `"ABCD and a tail long enough to move the buffer"`: `upcase!` answers its receiver, or nil when it changed nothing.

The long tail matters. After `upcase!`, `downcase!`, `capitalize!`, `swapcase!`, `squeeze!` and `succ!` the kept value is the receiver's own bytes until a change moves the buffer: with `label << "!"` master prints `"ABCD!"`, as CRuby does, and on `"abcd"` it is right up to 8 bytes appended and wrong from 9, with nothing said. After the other names the kept value is a String of its own and a one-byte change is lost as well: `strip!`, `lstrip!`, `rstrip!`, `chomp!`, `chop!`, `tr!`, `tr_s!`, `delete!`, `delete_prefix!`, `delete_suffix!`, `gsub!`, `sub!`, `next!`, `bytesplice`, `append_as_bytes`, and `concat` or `prepend` with other than one argument. Master refuses all of this for one name, `scrub!`.

After: refused. "the value of upcase! is kept in label and then changed in place (<<): a String is not yet shared by reference through that value. Change title itself instead of label".

The short append is refused too, though it is right on master today: master refuses the same program with `scrub!` in place of the method, whatever the length of the change.

What to write instead: change the receiver itself, `title << x if title.upcase!` (or `title.upcase!; title << x` when the nil does not matter). Measured on master for the 49 call forms of the list, with the receiver a local, a String two names hold, a parameter, a block parameter, an instance variable, a class variable, a global and a constant: every one builds and prints what CRuby prints when the receiver's own name is what is read afterwards. The sentence gives that rewrite, with the program's own names, for those receivers. It stops after "through that value" where the rewrite does not hold:

- an element of an Array (`r = a[0].strip!`): a change made on the element itself is lost on master as well (`a[0].upcase!` alone does not show in `a`). Taking the element into a local, changing that and storing it back (`t = a[0]; t.upcase!; t << x; a[0] = t`) answers as CRuby does for the 49 calls on `a[0]`, `a[-1]`, `@a[0]`, `$a[0]` and `A0[0]` (245 of 245);
- the value of a call (`r = box.name.upcase!`): master does not build 9 of the 49 calls on a reader's value, and none on a Struct member's;
- a program that defines a method of the name: its value may be a String of its own, and the program right as it stands.

The rewrite does not make every program right. Where the same String is read through another holder that master does not share with the receiver, the change is lost with or without this refusal, and the rewritten program is still wrong:

- a constant or a global given a local's String (`x = +"abcd"; S0 = x; S0 << t if S0.upcase!; p x` prints `"abcd"`);
- a `for` variable over an Array of Strings (`for s in a; s << t if s.upcase!; end; p a`);
- a parameter given a constant, or given an element of an Array of Strings (`def go(s) = (s << t if s.upcase!)`, then `go(G0); p G0` or `go(a[0]); p a`);
- a parameter given a Struct member (`go(o.s)`), which does not build.

In each of the six the program with no bang method at all (`S0 << t` alone) fails on master in the same way: the copy is made where the second holder is filled or the argument is handed over, not at the kept value. The refusal's sentence is printed for them, since the receiver there is a constant, a global, a `for` variable or a parameter.

A second name for the receiver (`s.upcase!; r = s`, or `r = s if s.upcase!`) is not the cure: it answers as CRuby on a local, a parameter and an instance variable, and is a silent copy on master when the receiver is a global, a class variable, a constant or a block parameter.

The test is the one master has for `scrub!` (a plain write of the call, whose local is the receiver of a String mutator), asked once the types have settled and narrowed four ways. All hold:

- the write is `r = s.upcase!`, the call itself or in parentheses, and the receiver is typed String. A box is not looked at: another class may define the name;
- every write of the local is such a value or nil;
- the local itself is the receiver of a String mutator other than `setbyte` somewhere in its scope;
- the receiver's String is held where it can be read again: an instance, global or class variable, a constant, a reader, a parameter, an element of an Array that one of those or a local holds, or a local that is read again in its scope.

The test reads the program, not its run, so it also refuses right programs, of these kinds:

- the change still fits the receiver's buffer, after one of the six names above;
- the method changes nothing at run time (`r = s.strip!; r << x if r` on a String with nothing to strip);
- the change never runs (`r << x if ARGV.size > 5`), or shows nothing (an empty append, a second `upcase!`);
- nothing reads the receiver's String afterwards: a variable, a reader or a parameter that is not read again (`def shout(s) = (r = s.upcase!; r << x; r)` called with a String of its own), a local read only before the write;
- the program reopens String and defines the name to answer a String of its own (`def squeeze!; dup; end`).

For each right program refused here, master refuses the same program with `scrub!` in place of the method (measured for every one below). No program of the repository is one.

Where master refuses a program later for another reason (a refinement beside the kept value, for one), this sentence now comes first.

Accepted, with master's C (`test/bang_value_kept_unchanged.rb`): a value only read (`p r`, `r.nil?`, `r == "x"`, `if s.strip!`), also beside a method elsewhere that has the call's name and changes its parameter; `r = x.dup.upcase!; r << y`; another class's `strip!`; an element of an Array a call has just answered (`line.split(",")[1].strip!`); `[]` on a String out of a mixed Array; a local that is another name for the kept value and is given a String of its own before it is changed.

`scrub!` is not in the list: its own refusal decides, and this pass changes no scrub! decision.

How: `refuse_kept_bang_values`, a pass of its own on the settled types beside `refuse_lent_ivar_copies` and `refuse_hash_pair_string_mutations`. It walks the program's calls and reads once, the first time a kept value needs them.

Still silent, as on master:

- the call anywhere but alone in a plain write: an arm of a conditional (`r = s.strip! || s`, `&&`, `if`, `unless`, `case`, a ternary), a chained write (`r = t = s.upcase!`), `r ||= s.upcase!`, after other statements in parentheses. The `scrub!` refusal reads none of these;
- the kept value changed through another name (`t = r; t << x`) or by a method it is handed to (`add(r)`). The `scrub!` refusal sees neither;
- the receiver in a box: an element of an Array whose Strings are boxed, a Hash's value, a block parameter over one, a rest parameter;
- an element of an Array a call has just answered that holds the caller's Strings (`h.values[0]`, `a.first(2)[0]`), an element of a nested Array (`a[0][0]`);
- the kept value changed after it is stored or returned: `@k = r; @k << x`, `a = [r]; a[0] << x`, `h[:k] = r`, a method that returns `r` to a caller that appends;
- the value kept anywhere but a local's own write: `begin`/`end`, `begin`/`rescue`, `ensure`, a rescue modifier, a multiple assignment, `.itself`, `.to_s`, `.tap` or `.then` over the call, a method's return, a block's or lambda's value, an Array literal, a numbered block parameter, a parameter default; an instance variable, a global or a constant as the target; a local also written from another String;
- `(s.upcase!) << x`, `s.upcase!.concat(x)`, `s&.upcase! << x`, `self.upcase!` inside a String method (`r = s&.upcase!` is refused, as `r = s&.scrub!` is);
- `setbyte` through the kept value when two names hold the receiver, and the mirror (`r = s.upcase!; s << x; p r`);
- `r = s.encode!(...)`.

## Measured

On master 4d56c157. Each program is compared with CRuby 3.3.6 run with `--enable-frozen-string-literal`; the new test and the two reject programs were also run under CRuby 4.0.7. Every program the branch compiles emits master's C. `append_as_bytes` is not in CRuby 3.3: its programs are compared with a stand-in written in Ruby that answers its receiver, with and without arguments, as the method of CRuby 4.0.7 does (checked there).

- 1,250 generated programs (each name, on a local, a String two names hold, an instance variable, a constant, a global, an element, a Hash value, a reader and a Struct member; the value printed, tested, compared, appended to, lent and stored): 245 that print a wrong answer on master are refused, 7 that did not build are refused by name, none that is right on master prints a wrong answer, none that failed loudly prints one. 531 right stay right. 102 right are refused: in 101 the method does nothing at run time; in 1 the receiver is read only before the write. Master refuses the `scrub!` form of each of the 102. 189 wrong stay wrong, and 146 differ from CRuby only in `equal?`.
- 564 programs written against the first form of this change: 101 wrong on master are refused, 283 right stay right, 79 wrong stay wrong. 42 right on master are refused: 17 the method does nothing at run time, 5 the change shows nothing, 13 the receiver is not read afterwards, 1 the receiver is `(+x)` of a frozen literal, 5 dead code, 1 that raises in CRuby too. Master refuses the `scrub!` form of each of the 41 that do not raise. 55 are refused on master too; 4 do not build on master, and 1 of them is now refused by name.
- The 150 kept-value programs of the String mutator sweep, on a String one name holds and on one two names hold: 48 wrong on master are refused, 27 right are refused (the call answers nil or raises; master refuses the `scrub!` form of each), 66 right stay right. The 1,500 programs of its five positions answer as on master.
- The one-byte append (`r = s.m!; r << "!"; p s`), one program for each of the 32 call forms that change the receiver: right on master for 7 (`upcase!`, `downcase!`, `capitalize!`, `swapcase!`, `squeeze!` with and without an argument, `succ!`), wrong for 25. All 32 are refused, and master refuses the `scrub!` form of all 32.
- What to write instead, the 49 call forms on the eight kinds of receiver the sentence names: `X << t if X.m!` builds and prints what CRuby prints in 392 of 392, `X.m!; X << t` in 392 of 392, and both with three arguments to `concat` in 16 of 16. With `concat`, `insert`, `prepend`, `replace` and `sub!` as the change, on eight of the calls: 640 of 640. None of these rewrites is refused. A second name (`X.m!; r = X`) is a silent copy in 196 of 196 on a global, a class variable, a constant and a block parameter. On eight forms of an Array element (`a[0]`, `a[-1]`, `a.first`, `a.last`, `a.fetch(0)`, `@a[0]`, `$a[0]`, `A0[0]`) `X.m!; X << t` is wrong in 392 of 392. The six holders where the rewritten program is still wrong, one program each with `upcase!` and one with no bang method: five print the String without the change, one does not build, on master and here alike.
- `tools/cident.sh 4d56c157`: 6123 identical, 0 differ, 0 refusal changes (the programs of test/, benchmark/ and packages/; optcarrot was not in the tree it ran in).
- `tools/refusals.sh`: pass (430 records, master 426). `make reject-test`: pass.
- Work counted at `-c` against master: 4,000 kept values in one scope, only read, 3,568.3M to 3,568.6M; with `setbyte`, 5,206.5M to 5,207.1M; 4,000 writes of one local, 520.9M to 521.0M; one kept value that is changed in each of 4,000 methods, 356.9M to 357.4M. The added work is 4.0 times at 4 times the size in each. One exception: a kept value that is changed and not refused asks its scope for a local (`scope_local`, which walks the scope's locals) once for the kept local and, when the receiver is a local of its own, once more for that. 4,000 of the first in one scope add 9.1M to 2,135M (+0.43%); 4,000 of the second (`sN = +"ab"; rN = sN.upcase!; rN << "y" if rN; p rN`) add 33.1M to 5,279M (+0.63%). That work grows with the square of the scope's locals, as master's own count in the same scope does.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7: `test/bang_value_kept_unchanged.rb` prints its `.expected` byte for byte, and the two reject programs run to the end)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: #
