### Letter GE on master 1df866be9c54 (the one build for its row)

Commit 709f24854f3a30af81b410c5c925590ac21e3f5e, tree ea0913dcfc7d, parent 1df866be9c54: the patch and message of 30c29281de06 (on 7bdde552e6ee), cut with commit-tree, no signature header, committer date = author date, the message ending in one newline. Body: `handover-cp/super-freeze-pr-body-v2.md`.

- BUILT there (gcc 13.3.0, clang 18.1.3). `test/super_freeze_builtin.rb` passes with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2 (6 of 6 cells) and built with `--share-strings`. Bare 1df866be9c54 does not build the test (C errors at its lines 80 and 82: "void value not ignored as it ought to be").
- `ruby tools/gate.rb check` with the piece staged: exit 0. `make gate` not run (no Ruby 4.0 here).
- The family of 514 (`handover-cp/gen-ge-super.rb`), by the emitted change (`handover-cp/bridge2.rb`, master 2801817b82e1 with the piece against master 1df866be9c54 with the piece): 403 programs with the same change, 111 with none; master's own C moved in all 514 between the two masters, the piece's lines in none. Its rows stand as run.
- Master 2a26683771cb (the tip at 15:15 UTC 10-07): merges clean (`git merge-tree` exit 0, tree a63b7509a512); the move changes `dyn_site_misses`, `kernel_module_function`, `dyn_blk_bits`, the `system` arms and `emit_system_splat`: none is the piece's (`comp_super_object_freeze`, the SuperNode arm of `infer_type`, `emit_super`, `an_phase_value_types`). Not built there.
- Checked for body -v2 on 2801817b82e1: a Struct whose freeze goes on to `self.n += 1` after the super, and an inherited writer on a frozen subclass object, print NoMethodError on master and 1 with the piece; their twins (the override named `seal` with a bare `freeze`) print 1 on master.
