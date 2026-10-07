<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
errors = []
3000.times do |i|
  begin
    raise ArgumentError, "bad #{i}" if i % 3 == 0
    raise KeyError, "missing #{i}" if i % 3 == 1
  rescue => e
    errors << "#{e.class.name}: #{e.message}"
  end
end
wrong = errors.select { |l| l.start_with?("KeyError: bad", "ArgumentError: missing") }
p wrong.size, wrong.first   # 0 and nil in CRuby; 79 and "KeyError: bad 1398" here
```

79 of the 2,000 lines carry the other class's name, in a plain run. `e.class.to_s`, an interpolated `e.class` and `e.inspect` are right; `.name` is wrong where a loop meets more than one error class.

The name of a rescued error's class is a fresh heap copy on each read (`sp_exc_class_name`). `sp_str_frozen_name`, Module#name's cache, keys a name by its address, on the premise that a name is a static string. A copy the collector had freed gave its address to the next copy, of another class's name, and the lookup answered the first.

Only a static name is now a key. Any other is interned by its bytes, which is what the cache stored for it, and is held while the interned copy is made: under `SPINEL_GC_STRESS=2` that copy was made from freed bytes. `e.class.name.equal?(e.class.name)` and `.frozen?` are true as before. One function, lib/spinel_rt.h +6.

Not covered: a class kept in a local across allocations, `k = e.class; ...; k.name`. It is right in a plain run; under `SPINEL_GC_STRESS=2` the copy `k` holds is freed before the read, which printed garbage and is now the stress check's abort ("the mark reached a freed slot"). `k.to_s` there is wrong on master and here.

Cost: none for a class the program names. 200,000 reads of one rescued error's `e.class.name` take 107,109,783 instructions for 3,389,917,085: the cache gained an entry a read and was walked each time. No program's generated C changes.

`test/exception_class_name_two_kinds.rb` prints 1,996 of 4,000 names wrong on master. It passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints class names, messages, counts and booleans)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
