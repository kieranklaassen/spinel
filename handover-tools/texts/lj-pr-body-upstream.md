<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
class Post
  include Loud
end
p Post.new.tag   # "TAG"
```

raised `super: no superclass method 'tag' for an instance of Post`. With a method of its own in the class, `def tag = "<" + super + ">"`, it printed `"<tag>"`; with that method in a subclass the C did not build.

A module that includes another holds the other's methods as copies of its own, and a `super` between them as a chain of its own. `process_include_body` copied the module's methods into the includer one by one under their names, and the chain stayed behind: the includer's `super` found no method, or one the class had under that name.

A method and those its `super` goes on to within the module are now copied as one run. It stands in the class where the single copy stood: behind the class's own method when that calls `super`, in front of an earlier include's copy.

Only where the run is sure to be Ruby's order: every link is between two instance methods of the module, neither taking a `&block`, the program has no `prepend`, and no class reaches a module by two ways (its own includes or a superclass's). Everywhere else the methods are copied as before, by the same lines.

Two commits: the first moves the copy of one method out of `process_include_body` (`tools/cident.sh`: 6470 identical, 0 differ), the second is the fix.

Depends on the pull request "A class held by value builds a super into an included module's method". A class held by value that includes such a module calls the run through the `super` that one repairs: 148 programs of the family below have such a class. On master 122 of them do not build, 14 raise and 12 are right; with this alone none builds, with both all 148 are right.

Not here:
- A module that reaches a class twice (`include Tag; include Loud`, or a superclass that includes `Tag`): Ruby keeps it once, where it stood first. The whole program is left as it is; `test/include_module_super_chain_held.rb` pins one that is right today.
- A program with a `prepend`, a link whose method takes a `&block`, a module with more than sixty links.
- Two module methods chained by a bare `super` that hands the caller's block on to a superclass method that yields: ten programs of the family. Five did not build and five raised; all ten now stop at `incompatible types when assigning to type 'sp_RbVal' from type 'int'`, as `include T; include L` with the same two methods does on master.
- `extend Loud` on a class or on an object, `defined?(super)` in the module's method, and an exception class that includes the module answer as before.

Measured on 42557a3c0e7c above that pull request, against CRuby 3.3.6, with 18,474 generated one-answer programs: four module graphs (one in another, three deep, two side by side in a third, a module in between), each module and the class with no method, a plain one or one that calls `super`, nine kinds of method (arguments handed on by `super(n + 1)` and by bare `super`, optional and keyword ones, a rest, an instance variable, a block by `&b` and by bare `super`), the include before the class's method, after it or in a reopening, another module included before, after or in the same statement, a superclass holding the include, the other module or the method, a module reached twice, a `prepend`. The C changes in 3,960: 786 wrong answers, 472 raises and 7 build failures become right, 2,685 stay right, and the ten above. The 14,514 others compile to the same C. `tools/cident.sh` against the pull request this depends on: 6471 identical, 1 differ (the new test), 0 refusal changes.

Compile time, the compiler's instructions under callgrind: 1,000 classes including a module of 20 methods with no `super`, +0.09%; 1,000 classes including `Loud` beside one class that reaches `Tag` twice, left as it is, +0.11%; 1,000 classes including `Loud`, -20.0%; 50 classes including a module of 50 such methods, +11.8%, all of it in `propagate_prep_params`, which runs once for each chain a class holds: 2,500 here, where the classes held none.

Tests: `test/include_module_super_chain.rb` (six of its seven lines are wrong on master, taken one by one) and `test/include_module_super_chain_held.rb` (right on master).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "A class held by value builds a super into an included module's method"
