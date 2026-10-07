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

An exception carries its class name as a bare C literal with no marker byte, so `sp_exc_class_name` (`lib/sp_exc.c`) hands Ruby a marked copy. It made that copy on the string heap, a new one each call. `e.class` puts it in a Class value, a plain struct `{cls_id, name}` that no root and no scan knows, so the copy was collected under a local, a parameter or an instance variable.

`sp_exc_class_name` now keeps one marked copy for a name, off the string heap, as a literal is. Every holder is right at once and no generated C changes. Reading `e.class` no longer allocates: 200,000 rescues that read `e.class.to_s` go from 427,496,929 instructions to 387,607,848 (callgrind).

One decision: the other way was to root the name in each holder of a Class value, which is codegen in several places and a root for every local that holds a class. With the copy kept, two `e.class.to_s` are the same String, as two `ArgumentError.to_s` already are on master; CRuby answers a new String for each. `to_s` is not frozen, before or after.

`test/exception_class_name_kept.rb` holds the class in a local, a parameter and an instance variable and reads it back by `to_s`, `name`, `inspect`, interpolation and `==`. On master (dafa0d047, gcc and clang) each of the seven forms is wrong in a plain run, so it is an ordinary test and not in `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is untouched)
- [ ] Depends on: # (nothing)
