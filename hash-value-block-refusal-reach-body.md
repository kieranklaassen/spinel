<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Hash value block that appends to its value parameter is refused when the block's own scope stores a String variable into the Hash. With the store out of that scope the program compiles and the append goes to a copy, with nothing said:

```ruby
def fill(h, k, v); h[k] = v; end
h = {}
fill(h, :a, +"q")
h.each_value { |x| x << "!" }
p h   # {a: "q"}; CRuby prints {a: "q!"}
```

The same holds for a Hash that is a parameter, a method's answer, an instance variable's or a global's, a `Hash.new` block's or `to_h`'s. A pass that runs once the sharing analysis has settled follows the Hash to those stores and refuses with the same message. It adds no sharing rule: under `--share-strings` it puts the route to `share_route_defer`, as the refusal in view does, where the stored value is typed a String, and refuses only what the rule leaves.

What is refused is what is refused in view: a stored String that is no literal. A frozen literal still compiles and raises FrozenError, and so does a local that only ever holds a literal. A parameter stands for the argument of the call that reached it, so `fill(h, :a, "lit")` beside `fill(other, :b, +"fresh")` refuses only `other`'s block, whichever call comes first. A method that assigns its Hash parameter (`h = {}`) stores into another Hash. Where no call says what a stored parameter is, it counts only where it is read as a String, as in view. A method that subclasses override is followed in the class of the receiver: `Plain.new.fill(h)` does not meet a subclass's `fill`, and `fill` called on self in an inherited `run` is the subclass's own when `run` was called on a subclass's object.

A local assigned from another local has that local's stores, in the block's own scope too. master's list stops at the assignment, so `x = {}; x[:a] = +"q"; h = x; h.each_value { |s| s << "!" }` loses the append there and is refused here. The price is a block over a local that holds one of two Hashes (`h = lists`, or else `h = names`): it is refused for the String Hash though it only ever appends to the Arrays, as master refuses it when the two Hashes are built under `h` itself.

Right programs refused: none of the repository's (cident below) and none of 2,052 generated ones (792 silent wrong answers become refusals, 1,048 keep master's C, 212 are refused by both; under `--share-strings` 24, 1,802 and 226, each of the 24 wrong on master under the flag). The corner is master's own: a program refused today when its Hash goes through one variable in the block's scope is refused when that variable is a parameter, an instance variable or a second local (a frozen literal iterated ahead of a fresh String, a constant holding a literal, `"q".dup.freeze`, a store after the block, an appended copy nothing reads, two objects of one class filled through different methods).

docs/limitations.md says where the store is looked for and names the stores that are still not found, the limits of the walk among them (64 calls, six rounds of a cycle of methods, 64 classes a method's self is of). Past a limit a store is missed, as on master; nothing is refused for it.

Compile time: a holder's stores are listed once and kept for every later value block, and a call turns a method's list into its own arguments. scale-test prints master's lines, and on 23 generated shapes the added work doubles with the program (one method with K calls of itself adds 163,602, 326,602, 652,602 and 1,304,602 counted steps at K = 1000 to 8000). Five shapes grow faster, where master's own tables do: K locals in one scope, each a Hash under its own block or the receiver of a storing call (at most 0.32% of master's count at K = 1000), and K classes that define one method with a value block, reached by K calls (master's call-site table lists every call under every such method: at most 1.55% of master's count at K = 400).

## `make gate` (on this branch merged with current master)

```
cloud container, CRuby 3.3.6: the full gate is owed on a machine with Ruby 4.0
cident: 6407 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against 4f8b737c1)
refusals: pass (556 records)
reject-test: pass
share-strings-test: pass
scale-test: instance_eval forwarding work at 2x the wrappers is 1.71x (limit 2.50)
scale-test: work at 4x the program is 4.74x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.13x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.17x (linear 4.00, limit 4.50)
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (checked here against CRuby 3.3.6 only; the test prints Hashes as Arrays so its text is the same on both)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (optcarrot is not in this container; the C of every repository program is unchanged)
- [ ] Depends on: # (nothing)
