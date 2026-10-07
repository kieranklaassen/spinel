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

With `--share-strings` master (759d120fd) prints `"ab"` twice; CRuby and this print `"abz"` twice. Written `r.x = s` it is right under the flag. (`spinel diff` takes no compiler flag, so there is no report to paste.)

The share walk has a case for `o.x ||= v` and `o.x &&= v`. It asks the node for `"read_name"`, a field the parser does not write; the attribute's name is in `"name"`. So the case finds no attribute, the value joins no instance variable, and the local and the slot each keep a copy.

Reading the right field for every such write is too much. A conditional store is not `x=` called with the value, and the unknown value the case gives today is what keeps other programs right or refused: an element, a Hash's value, a container or a call's answer on the right; the write used as a value; a writer written by hand. So the case joins the slot only for one store:

- the write is a statement, and not the last of its body;
- its value is the read of a local that holds a String;
- `x` and `x=` are attr methods, and no method of either name is written by hand.

Every other conditional attribute write keeps the unknown value and its generated C. The walk runs only under `--share-strings`: the default build's C is unchanged.

Of 6,468 programs around an attribute `||=` / `&&=` (eleven shapes of class, among them a writer or a reader written by hand, a Struct, a module and two classes that share the attribute's name; twelve kinds of value; the write as a statement and as a value, on an empty and on a filled slot; seven uses of the String), the default build gives 6,184 the same C and refuses 284 in the same sentence. With the flag 396 change: 136 go from wrong to right, 256 that are right print the same, and 4 are refused as before, at another line. None that is right is lost or refused.

Where the local is a method's parameter, a wrong answer can become a refusal instead of the right answer:

```ruby
class Box
  attr_accessor :x
  def fill(v)
    self.x ||= v
    self
  end
end
r = Box.new
arr = [+"ab", +"cd"]
r.fill(arr[0])
r.x << "z"
p r.x
p arr
```

CRuby prints `"abz"` and `["abz", "cd"]`. With the flag master prints `"ab"` and `["ab", "cd"]`; this refuses the program ("the Strings this literal holds are shared with another name and changed in place, and a typed String container cannot hold the shared handle yet"). Written `self.x = v` it builds and is right, on master too; this does not make the conditional store build there. A method that returns the parameter it or-assigned (`def set(r, s); r.x ||= s; r.x << "z"; s; end`) goes the same way: wrong on master, refused here ("a String a method returns as its parameter is mutated in place"), right when written with `=`. Of 1,822 further programs with the write inside a method (counted on 9274c732e; the programs named here re-run on 759d120fd), 14 go from a wrong answer to a refusal so, and one that master refuses (the parameter is given another object's attribute while a second class holds an Array of Strings under the same name) builds and is right.

Not here, each printing with the flag what it prints on master:

```ruby
a = [+"ab"]
r.x ||= a[0]          # an element on the right: ["ab"] and "ab"
r.x << "z"

def pick(t) = t
r.x ||= pick(s)       # a call's answer on the right: "ab" twice
r.x << "z"
```

`tools/cident.sh 759d120fd`: 6425 identical, 4 differ, 0 refusal changes: the four tests that print the compiler's revision. `make share-strings-test` passes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
