<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**The cost first: a block's parameter handed on from inside a class is refused where it was built.** `xs.each { |h| app(h, &pr) }`, where `app` is a top-level method that yields its parameter to a proc that appends, is refused by master at top level, in a free function and where the class defines `app` itself. Written inside a class it was built, and it printed CRuby's answer in 35 of the 583 programs below. It does not always: with a second block in the method whose parameter has the same name, the first loses its append on master.

```ruby
def app(s, &b) = b.call(s)
class K
  def go
    [+"a"].each do |h|
      pr = proc { |k| k << "x" * 20 }
      app(h, &pr)
      p h.size          # CRuby: 21    Spinel: 1
    end
    xs = [+"a"]
    xs.each do |h|
      pr = proc { |k| k << "x" * 200 }
      app(h, &pr)
    end
    p xs[0].size
  end
end
K.new.go
```

The fault itself:

```ruby
def app(s, &b) = b.call(s)
$g = +"g"
class Holder
  def go
    pr = proc { |k| k << "!" }
    app($g, &pr)
    p $g
  end
end
Holder.new.go
```

```
spinel diff: output-diff
-"g!"
+"g"
```

Written at top level, the same call is refused (`a String is passed to `app`'s parameter `s` through a yield into a block argument ... from a global variable`). Inside the class it is built and the append is lost.

`refuse_static_target` names the method a call reaches. For a bare call or a call on `self` it took the class of the scope the call is written in and asked that class's chain alone; the free function was asked only where there is no class. So a top-level method called from an instance method, a class method, a module's method or a block in one was never found, and the refusals that start from the method called returned before they looked at the arguments: a parameter yielded on to a block or a proc (`refuse_yield_handle_args`) and a repeated keyword. The third caller already asked the free function by hand. The lookup now does that for all three: the class's chain, then the free function. A call on any other object asks its class alone, as before.

583 programs: seven kinds of String variable (a local, a parameter, an instance, a global and a class variable, a block's parameter, a captured local), eleven ways to hand it to a top-level method that yields it on (a proc, a lambda or a Method passed with `&`, to `yield` or to `b.call`; a rest; a keyword; a second parameter ahead of it; a parameter that also takes an Integer; a literal block; two that only read), and eight places for the call (top level, a free function, an instance method, a class method, a module's method, a block in a method, a subclass's method, and a class that defines the method itself). Master against this:

| on master | with this | programs |
|---|---|---|
| wrong | refused | 105 |
| right | refused | 35 |
| right | right, master's C byte for byte | 376 |
| refused | refused | 67 |

In each of the five places inside a class or a module the verdicts are now those of the place where the class defines the method itself: 21 wrong and 7 right programs refused, 49 right with master's C. A repeated keyword (`app(k: o, k: s)`, where `app` appends to `k`) is refused at top level and printed `"s"` for `"s!"` inside a class; it is refused in both now.

Under `--share-strings` nothing changes: the three reject tests build and print CRuby's answers on master and with this, and are in `test/share/reject.list`.

**Not in this change.** `self.app(s, &pr)` to a top-level method builds on master and raises NoMethodError when it runs; where the call would hand over a copy it is now refused when built, and otherwise it raises as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
