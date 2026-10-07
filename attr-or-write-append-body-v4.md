<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An append to a String that `r.x ||= v` stored went to a copy. Stated cost, compile time only: where this types an or-written attribute's slot, the inference runs one round more, the round a slot written with `=` is given. The compiler's counted work rises 6% in a program of 1,000 classes and 10% in the eight lines below (135,257 steps to 148,777; written with `r.x = +"ab"` they count 158,111 on master); the table is further down. A program with no attribute `||=` is not walked, and one whose or-written attribute nothing mutates pays the walk alone, 0.05%. Of the 3,100 programs below the slot is typed in 180; 49 of those are right on master and print the same (a bang method that changes nothing, `r.x.strip!` on "ab"), so they pay it for no change.

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

That is master (759d120fd). Written `r.x = +"ab"` it is right.

`infer_ivar_types` types an attribute's slot from `o.x = v`. A slot that only `o.x ||= v` / `o.x &&= v` write stays untyped, the backstop boxes it, and the append goes to a copy of the boxed String. Now, once the types have settled, such a slot whose conditional writes each give a String takes the String's type, as `o.x = v` would have given it.

Not every such slot. The box does two things the typed slot does not: it hands every reader the one String, so a freeze through a second name is seen, and its mutators raise NoMethodError while the slot is nil. So the slot is typed only where neither can show. The test is by name, over the whole program, in one walk:

- a mutator is called on a read of the attribute (one nothing mutates is right in its box and keeps it);
- each `||=` / `&&=` of the attribute is a statement given a fresh String: an interpolation, `+"lit"`, `String.new`, or the `dup` of a literal or of one of these (the `dup` of anything else may be nil's);
- each read is the receiver of a String method that answers something else (`length`, `bytesize`, `empty?`, `nil?`, `dup`, `upcase`, `downcase`, `reverse`; `==`, `!=`, `+`, `include?`, `start_with?`, `end_with?` given Strings), an argument of `puts`, `print` or a statement `p`, the part of an interpolation, a statement, or the receiver of a mutator;
- each mutator is a statement that stands after a `||=` of the attribute on the same receiver, self or a local bound once, in one sequence (a conditional or a `while` in it counts);
- nothing else names the attribute: no `x=`, no method of the name, no Symbol outside its `attr_accessor`, no alias, String is not reopened, and the program calls nothing that takes a name it computes (`send`, `instance_variable_get`, `instance_variable_set`, `remove_instance_variable`).

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
q.x ||= s                   # a String given from a local, or its `dup`
q.x << "z"

r.x ||= +"ab"
r.x << "z"
p r.x.size                  # `size`: on a slot still nil a typed slot's error names `length`
```

Of 3,100 programs around an attribute `||=` / `&&=` (attr_accessor, a subclass, a module, a Struct member, `self.x`, `&.`; fourteen kinds of value; 92 uses of the String; 32 ways to freeze it; 109 written at the edges of the test above; 48 that store nil by `instance_variable_set` or `remove_instance_variable`; 345 given a `dup` of nineteen receivers, fourteen of them no String for certain; 30 that read a slot still nil), the generated C of 180 changes, the same 180 in the default build and under `--share-strings`: 104 go from wrong to right, 27 that raised NoMethodError (the box has no `concat`, `prepend` or `reverse!`) are right, and 49 that are right print the same. None that is right changes and none is refused. The 65 programs that freeze the String through another name, the 48 that store by a computed name and the 255 given such a `dup` all keep master's C.

Compile time. A program with no attribute `||=` is not walked. `spinel -c` on six programs of 1,000 classes, user and system seconds, the lowest of twelve runs, and the compiler's counted work (`build/spinel-work`):

| | master | this |
|---|---|---|
| no `\|\|=`: every attribute written with `=` | 1.84 s, 425.3M | 1.88 s, 425.3M |
| the same and one `\|\|=` whose slot is typed | 1.87 s, 434.9M | 1.97 s, 459.8M |
| the same and one `\|\|=` whose String is only read (the walk alone) | 1.77 s, 434.8M | 1.81 s, 435.0M |
| the same and one `\|\|=` whose String has a second name (the walk alone) | 1.86 s, 435.3M | 1.96 s, 435.5M |
| each class its own or-written attribute | 1.48 s, 341.1M | 1.57 s, 360.7M |
| one class, its attribute or-written on 1,000 objects | 1.84 s, 433.3M | 1.98 s, 457.3M |

Where a slot is typed (the second row and the last two) the inference runs on with the String slot, for one round: the count rises 6%; the seconds vary by 0.1 s from run to run on this machine (the first and fourth rows) and show no more than that. The slot is typed once the rounds have settled, and the Strings stored in it are promoted at once, as the round after `o.x = v` types a slot promotes them, so the next round is the one that finds nothing to change: the eight lines at the top take three rounds on master, four with this, and four on master written with `=`. In a small program a round is a larger share: those lines count 135,257 steps on master and 148,777 with this, 10%. In the last row the generated C of the 1,000 writes changes too. The walk alone (the third and fourth rows) is linear, 0.05% of the count.

The 385 lines in `src/analyze.c` are that test: each clause above is a list the walk checks, and without any one of them a program that is right on master goes wrong (typing every such slot lost 63 of 2,670).

Not in this change, the same on master: written `r.x = +"ab"`, the slot is typed, and `r.instance_variable_set("@x", nil); p r.x` raises TypeError where CRuby prints nil; with the store in a method the generated C does not compile.

`tools/cident.sh 759d120fd`: 6426 identical, 5 differ, 0 refusal changes, 0 refused by both, 0 not in the reference: `test/attr_or_write_string_append.rb` and the four tests that print the compiler's revision. The second test, `test/attr_or_write_string_ivar_set.rb`, is right on master and keeps its C: the walk is over the whole program, so a line with `instance_variable_set` cannot stand in the first. `make share-strings-test` passes and `make scale-test` gives 1.71, 4.74, 6.13 and 4.17.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
