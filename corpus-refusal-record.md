<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`make refusals-corpus-test` fails on master:

```
refusals: FAIL (the refused programs or their messages changed)
5a6,8
> == test/array_push_stmt_operand_order.rb [promote] rc=1
> spinel: an attribute writer given a Array, which no conversion keeps in its sp_PolyArray * slot
> spinel: 1 refusal, nothing written
```

The test came with #7231 and has printed this under `--int-overflow=promote` since it was merged; its record was never added. This adds it with `tools/refusals.sh --update --corpus`. Nothing in the compiler changes, and no other line of the file moves.

The refusal is right. In promote mode a method's Integer answer is boxed, so `@drum << @hand.set` makes `@drum` an Array of anything, and `@owner.drum = [300]` hands an Integer Array to an attribute writer whose slot no conversion keeps. The conversion that exists copies the Array, which would leave the caller and the instance variable with two Arrays.

## `make gate` (on this branch merged with current master)

```
cloud container, CRuby 3.3.6, master 3a95d7dd (the same two lines merged with b726ae01): only the two refusal legs were run; the full gate is owed
refusals: pass (7 records)      # tools/refusals.sh --corpus
refusals: pass (424 records)    # tools/refusals.sh
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no test is added; the one file changed is the refusal record, which the tool writes)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (no compiler change)
- [ ] Depends on: # (nothing)
