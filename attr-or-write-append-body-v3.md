<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An append to a String that `r.x ||= v` stored went to a copy. Stated cost, compile time only: where this types an or-written attribute's slot, the compiler's counted work rises 12% to 15% (the table below). A program with no attribute `||=` is not walked, and one whose or-written attribute nothing mutates pays the walk alone, 0.05%. Of the 2,673 programs below the slot is typed in 73; 5 of those are right on master and print the same (a bang method that changes nothing, `r.x.strip!` on "ab"), so they pay it for no change.

```ruby
class Box
  attr_accessor :x
end

r = Box.new
r.x ||= +"ab"
r.x << "z"
p r.x
```

```
spinel diff: output-diff
  program: witness.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"abz"
+"ab"
```

That is master (fc6e90cc8). Written `r.x = +"ab"` it is right.

`infer_ivar_types` types an attribute's slot from `o.x = v`. A slot that only `o.x ||= v` / `o.x &&= v` write stays untyped, the backstop boxes it, and the append goes to a copy of the boxed String. Now, once the types have settled, such a slot whose conditional writes each give a String takes the String's type, as `o.x = v` would have given it.

Not every such slot. The box does two things the typed slot does not: it hands every reader the one String, so a freeze through a second name is seen, and its mutators raise NoMethodError while the slot is nil. So the slot is typed only where neither can show. The test is by name, over the whole program, in one walk:

- a mutator is called on a read of the attribute (one nothing mutates is right in its box and keeps it);
- each `||=` / `&&=` of the attribute is a statement given a fresh String: an interpolation, `+"lit"`, `String.new`, a `dup`;
- each read is the receiver of a String method that answers something else (`size`, `length`, `bytesize`, `empty?`, `nil?`, `dup`, `upcase`, `downcase`, `reverse`; `==`, `!=`, `+`, `include?`, `start_with?`, `end_with?` given Strings), an argument of `puts`, `print` or a statement `p`, the part of an interpolation, a statement, or the receiver of a mutator;
- each mutator is a statement that stands after a `||=` of the attribute on the same receiver, self or a local bound once, in one sequence (a conditional or a `while` in it counts);
- nothing else names the attribute: no `x=`, no method of the name, no Symbol outside its `attr_accessor`, no `send`, no alias, and String is not reopened.

The mutators are `<<`, `concat`, `prepend` and `replace` given Strings, and `clear`, `upcase!`, `downcase!`, `capitalize!`, `swapcase!`, `strip!`, `lstrip!`, `rstrip!`, `chomp!`, `chop!`, `squeeze!`, `reverse!`, `succ!` and `next!` given nothing. The others are left out because a typed slot does worse with them through a reader than the box does: `gsub!`, `sub!`, `tr!`, `delete!` and `bytesplice` are refused there, `insert` past the end raises no IndexError (`[]=`, `slice!` and `setbyte`, which take an index too, are left out with it), and an argument that is no String is appended without a TypeError.

Anything else keeps the box and master's generated C. Not cured here, each printing what it prints on master:

```ruby
r.x ||= +"ab"
3.times { r.x << "a" }      # an append in a block: the block may be kept and run before the write

def add(o)                  # an append in another method than the `||=`
  o.x << "m"
  nil
end
add(r)

t = r.x                     # the String under a second name
t << "y"

s = +"cd"
q = Box.new
q.x ||= s                   # a String given from a local
q.x << "z"
```

Of 2,673 programs around an attribute `||=` / `&&=` (attr_accessor, a subclass, a module, a Struct member, `self.x`, `&.`; fourteen kinds of value; 92 uses of the String; 32 ways to freeze it; 109 written at the edges of the test above), the generated C of 73 changes, the same 73 in the default build and under `--share-strings`: 55 go from wrong to right, 12 that raised NoMethodError (the box has no `concat`, `prepend` or `reverse!`) are right, one that never ended (`while r.x.size < 5; r.x << "w"; end`) ends, and 5 that are right print the same. None that is right changes and none is refused. The 65 programs that freeze the String through another name all keep master's C.

Compile time. A program with no attribute `||=` is not walked. `spinel -c` on six programs of 1,000 classes, user and system seconds, the lowest of eight runs or more, and the compiler's counted work (`build/spinel-work`):

| | master | this |
|---|---|---|
| no `\|\|=`: every attribute written with `=` | 2.08 s, 424.2M | 2.03 s, 424.2M |
| the same and one `\|\|=` whose slot is typed | 2.00 s, 433.8M | 2.26 s, 483.8M |
| the same and one `\|\|=` whose String is only read (the walk alone) | 2.01 s, 433.7M | 1.93 s, 433.9M |
| the same and one `\|\|=` whose String has a second name (the walk alone) | 2.04 s, 434.2M | 2.04 s, 434.4M |
| each class its own or-written attribute | 1.56 s, 340.1M | 1.53 s, 381.0M |
| one class, its attribute or-written on 1,000 objects | 1.70 s, 424.2M | 2.00 s, 489.3M |

Where a slot is typed (the second row and the last two) the inference runs on with the String slot: the count rises 12% to 15%, and the seconds follow it in the second and last rows. In the last the generated C of the 1,000 writes changes too. The walk alone (the third and fourth rows) is linear, 0.05% of the count. The first row, where the work is the same, shows what the seconds vary by.

The 378 lines in `src/analyze.c` are that test: each clause above is a list the walk checks, and without any one of them a program that is right on master goes wrong (typing every such slot lost 63 of 2,670).

`tools/cident.sh`: 6399 identical, 5 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against fc6e90cc8): the new test and the four tests that print the compiler's revision. `make share-strings-test` and `make scale-test` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
