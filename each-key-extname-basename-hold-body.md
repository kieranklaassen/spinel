## What this changes

```ruby
def mk(i) = {a: i, b: 2}
p mk(1).each_key.to_a
s = "hello"
p File.basename(s + ".rb", ".rb") + File.extname(s + ".txt")
```

prints `[:a, :b]` and `"hello.txt"`; under `SPINEL_GC_STRESS=2` it prints `[nil, nil]` and a String of 0xdb bytes.

`sp_enum_hash_side`, which makes the Array for `each_key.to_a` and `each_value.to_a`, allocates it before it reads the Hash. `sp_file_extname` allocates its answer before it copies from `path`. `sp_file_basename2` roots `path` and `suffix` but not the fresh String `sp_file_basename` just answered, across its own allocation. A value made in the call is held by nothing else there.

Each now roots what it reads. No generated C changes. No plain run showed a wrong answer (2,000,000 turns of each): the answer's growth is served from another size class, so the freed slot is not handed out again before the copy ends. Cost (callgrind, instructions a call): `File.extname` 396 against 378, `File.basename` with a suffix 655 against 628; `each_key.to_a` measures the same before and after.

On master b44861f8: `make cident` reports 6,354 identical, 0 differ.

Test: `test/hash_side_file_name_arg_rooted.rb`, also in the `SPINEL_GC_STRESS=2` list.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6, the one at hand; the test prints no Hash, so nothing in it differs between the two)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

