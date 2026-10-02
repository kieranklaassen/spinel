<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`Node.new` reaches the allocator knowing two things where it is compiled, the size of a Node and that it has no finalizer. `sp_gc_alloc` works both out again on every call: a load for the size class, a load for the slot size, a test for the finalizer, and a jump into the middle of the zeroing stores. On gcbench the constructors are half of what the program runs and `sp_gc_alloc` a fifth.

`SP_POOL_NEW`'s slab arm now calls `sp_gc_alloc_sized` (lib/sp_alloc.h), an inline switch on the size class that folds to one direct call of `sp_gc_alloc_32` .. `sp_gc_alloc_256` (lib/sp_slab.c). Each is the lean front again with the class and the slot size as constants: 28 instructions and no frame for a 96-byte slot. It hands the full form whatever `sp_gc_alloc` hands it, so the trigger, the stress switch, the verifier and the report see every allocation they saw, and an object past 256 bytes takes `sp_gc_alloc` as before. `sp_slab_init` checks that the size classes are where the switch takes them to be.

No file under src/ changes, so the generated C is the same byte for byte, optcarrot's included. One line of lib/spinel_rt.h changes, the call in `SP_POOL_NEW`; everything else there is as it was and no name goes away.

Instructions under callgrind (gcc 13.3, x86-64), 7337219d to this branch:

| benchmark | master | this | |
|---|---|---|---|
| gcbench | 3,427,771,290 | 3,139,140,587 | -8.4% |
| ao_render | 1,183,918,089 | 1,090,723,568 | -7.9% |
| binary_trees | 37,519,875 | 34,966,295 | -6.8% |
| linked_list | 379,406,881 | 358,723,522 | -5.5% |
| splay | 67,318,719 | 66,152,868 | -1.7% |
| rbtree | 346,677,771 | 344,607,529 | -0.6% |

The 19 other benchmarks with a pooled constructor, and fib and str_concat with none, stay within 0.05% except micro_lisp (-0.2%). The largest rise is the check in `sp_slab_init`, about 250 instructions once at startup. On the clock the gain is inside my machine's noise: the instructions removed are cheap ones.

Two tests join `GC_MINOR_TESTS`. `test/gc_alloc_front_sizes.rb` fills every size class a front takes with a class of its own, built in turn so that every run is open, reads them back after a collection, and then refills recycled slots with objects whose fields are left unset. `test/gc_alloc_front_threads.rb` has five threads construct at once. Each fails on a runtime broken on purpose: the zeroing removed (a segfault), a front handing out the next smaller slot (`[11]`), every thread bumping one worker's run (30 of 30 runs).

Measured and not taken: bumping the run inline in the constructor. It gives more (gcbench -13.5%, ao_render -15.5%, binary_trees -10.6%), but tree_walker_frames, which constructs 30 objects, rose 1.4%: with larger constructors in the file gcc stops inlining `_sp_gc_root_push` into the interpreter's visit, 600,000 calls. Out of line, nothing a constructor's caller compiles to changes size, and the slab's worker struct stays private to lib/sp_slab.c. If you would rather have the inline form I can send it with the optcarrot numbers.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
