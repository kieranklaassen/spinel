<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

The class of a rescued error, held in a variable while Strings are made, answered with another String:

```ruby
def churn(n)
  keep = []
  n.times { |j| keep << "junk-" + (j % 10).to_s + "-junk-" }
end
bad = 0
1000.times do |i|
  begin
    raise ArgumentError, "bad #{i}"
  rescue => e
    k = e.class
    churn(400)
    bad += 1 unless k.to_s == "ArgumentError"
  end
end
p bad    # 0 in Ruby; 55 on master, where k.to_s is "junk-0-junk-"
```

`sp_exc_class_name` (`lib/sp_exc.c`) named the class with a fresh copy on the string heap each call. `e.class` puts that copy in a Class value, a plain struct `{cls_id, name}` that no root and no scan knows, so it was collected under a local, a parameter or an instance variable. It now keeps one marked copy for a name, off the string heap, as a literal is. No generated C changes.

One decision: the other way was to root the name in each holder of a Class value, in several places of the code generator. With the copy kept, `e.class.to_s.equal?(e.class.to_s)` is true, where Ruby and master say false; master already answers true for `ArgumentError.to_s.equal?(ArgumentError.to_s)` and for `k.to_s.equal?(k.to_s)`. `to_s` is not frozen, and a mutator on it leaves the class's name as it was.

`test/exception_class_name_kept.rb` holds the class in a local, a parameter and an instance variable. On master (06064727f, gcc and clang) each of its seven forms is wrong in a plain run, so it is an ordinary test and not in `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is untouched)
- [ ] Depends on: # (nothing)
