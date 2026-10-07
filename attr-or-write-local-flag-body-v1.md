<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Box
  attr_accessor :x
end

r = Box.new
s = +"ab"
r.x ||= s
r.x << "z"
p s, r.x
```

With `--share-strings` master (a2bd89005) prints `"ab"` twice; CRuby and this print `"abz"` twice. Written `r.x = s` it is right under the flag. (`spinel diff` takes no compiler flag, so there is no report to paste.)

The share walk has a case for `o.x ||= v` and `o.x &&= v`. It asked the node for `"read_name"`, a field the parser does not write; the attribute's name is in `"name"`. So the case found no attribute, the value joined no instance variable, and the local and the slot each kept a copy. The change is that one word in `src/analyze_share.c`.

Of 2,564 programs around an attribute `||=` / `&&=` (attr_accessor, a subclass, a module, a Struct member, `self.x`, `&.`; fourteen kinds of value; a slot that also holds another kind; 92 uses of the String; 32 ways to freeze it), the default build's generated C is the same for every one. With the flag the C of 36 changes: 16 go from wrong to right, 10 that are right print the same, and 10 that print a wrong answer are refused. Those ten are `r.x ||= [+"a"]; r.x << +"b"; r.x.last << "!"`, which printed `["a", "b"]`: it now meets the flag's refusal of a typed String container that would hold a shared handle, as it does on master when written with `=`. None that is right changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
