<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def pick(n) = n > 0 ? {"a" => 1, :s => 2} : [1, 2]
x = pick(1)
p x.fetch(:zz) { |k| k }   # C did not build; CRuby prints :zz
```

`fetch` with a block that takes the missing key did not build in C when the receiver may be a Hash or an Array and the key is a Symbol or a String literal. The fetch itself types the still untyped local as a Hash of that key type for one round of inference, so the block's parameter is a Symbol's or a String's slot, and rightly. But the local is boxed a round later, the Hash arm holds its key boxed, and that boxed key was assigned to the typed slot.

The key is now unboxed into the slot where a list shows the slot is the key's own: the key is a Symbol or a String literal, nothing assigns the parameter, every read of it is a call's receiver, an interpolation or the block's value, and the block answers a plain value. Inference does not change. Everything outside the list fails in C as it did, and so does a program in which another fetch block is left with a slot of another type than its key (a Symbol key and a String key fetched from one receiver). The list is all or nothing for the program, so under `--share-strings` one slot that is a shared handle stands every fetch block of the program down: this change's own test does not build with the flag, as it does not on master, and `share-strings-test` does not run it.

Every other corpus program compiles to the same C in both overflow modes. Whether a fetch block is left behind is the whole program's answer, so it is asked once and kept, not asked again by every fetch block: under callgrind, spinel takes 1.008 times master's instructions on 1,000 such fetch blocks, and 1.0003 times on 1,000 that are right on master.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 9c7ea3ce0 merged with this branch's 2 commits (f7eb6e17e, 2b9f90571): the build; `tools/gate.rb check`; the new test in the twelve cells without `--share-strings` (with the flag it does not build, as on master) and the parameter fix's test in all eighteen (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (the C of this branch's two tests differs; the other 6,513 corpus programs, optcarrot among them, compile to the same C; so does every other program that compiles with `--int-overflow=promote` (6,505) and with `--share-strings` (6,404)); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/poly_fetch_block_key_param.rb.expected` exactly)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at 9c7ea3ce0)
- [x] Depends on: # (the pull request "A fetch block's parameter is boxed where its type is not the key's"; its commit f7eb6e17e is this branch's first, with the same id)
