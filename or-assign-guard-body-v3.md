<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
h = {a0: +"s"}
h[:a1] = h[:a0]
h[:a2] = h[:a1]
# ... nine of these
h[:a0] << "v"     # the compiler does not finish in 90 seconds; with eight it takes 10 (master 52c5ccf74)
```

The same in an Array's slots, in a Hash an instance variable or a parameter holds, and in two Hashes that store each other's elements.

An append through an element demands the container's stored Strings as shared handles. A stored value that is boxed is followed to the element read it is, and `strbuf_demand_elem_arg` starts the walk of that read's container. Since #7369 a read whose walk is under way answers 0, which ended the recursion that used to overflow the stack. A second read of the same container is still another read, so the stores are walked once more for it, and again inside that: n! walks for n such stores.

The walk is of the stores into the container a local or an instance variable holds, whichever element is read. So a read of that container met inside the walk now answers 0 as the same read does; the walk on the stack reaches every store the inner one would. No sharing rule changes and no generated C.

**Nearest upstream changes, and why this is not one of them.** #7369 is the guard this completes. The walk-speed changes merged since (#7365's memo and the per-method one beside it, #7384, #7386, #7388, #7390, #7392, #7396 to #7402) make one walk cheaper or remember a walk that changed nothing. None touches this guard, and here it is the number of walks that grows. A walk that reaches a container moves the memo's generation whether it changed anything or not, so the memo never holds one of these. #7452 added a caller of `strbuf_demand_elem_arg` (a method that hands out an element) and left the guard as it was. #7496 (the cap on inference rounds) is another loop: with it in master the ten programs below still give no answer.

**Measured on master 52c5ccf74.**

| | master | this commit |
|---|---|---|
| 26 programs with eight to forty self-stores in one container, or in two or four that store each other's (60 seconds allowed, compared with CRuby 3.3.6) | 16 as CRuby, 10 give no answer in 60 seconds | 26 as CRuby |

A row of eight compiles in 10 seconds on master and 0.01 with this, to the same C; nine and forty do not finish in 90 seconds on master and take 0.01 and 0.03.

**Generated C.** `tools/cident.sh 52c5ccf74`, taken with the new test and its `.expected` set aside: `cident: 6127 identical, 4 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against 52c5ccf74)`. The differing files are the programs that print the compiler's revision. The test is set aside because `tools/cident.sh` hands every test of this tree to the reference compiler with no time limit and master's compiler does not finish this one, so `make cident REF=<master>` does not return with the test in the tree. On master f8abc3e18, with the or-assign commits on top and master's four walk memos switched off as well, the C is the same for 9,227 programs (the corpus and the program sets of this work).

**Test.** `test/container_many_own_elements.rb`: twelve self-stores in a local Hash, an Array, an instance variable's Hash read into an appended local, and a parameter's Hash. It prints the same under `SPINEL_GC_STRESS=1` and `2`. Master's compiler does not finish it (stopped at 90 seconds here); that is its point, so it stays at twelve.

The change is in `strbuf_demand_elem_arg` and one helper beside it; no function over 1,000 lines grows.

The `.expected` file was written with CRuby 3.3.6 run with `--enable-frozen-string-literal`, and CRuby 4.0.7 prints the same 14 lines.

## `make gate` (on this branch merged with current master)

```
not run in full here: the full gate runs on the Mac before anything goes upstream.
In the cloud, on this commit alone on master 52c5ccf74:
tools/gate.rb check: passes (no Ruby 4.0 here, so it did not compare .expected)
cident: 6127 identical, 4 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against 52c5ccf74) (with the new test set aside, see above)
On this commit alone on master f8abc3e18, `make test OPT=-O1`:
Tests: 5950 pass, 2 fail, 0 error
FAIL: pkg.tmpdir.tmpdir_expand_usable
FAIL: socket_ipv6_and_class_methods
(the two that fail in this sandbox on master too); its C-side legs pass.
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared under CRuby 4.0.7: equal, 14 lines)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
