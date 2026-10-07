<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def churn
  a = []
  4000.times { |i| a << ("filler string number " + i.to_s) }
  a.length
end

def nested(n)
  begin
    begin
      raise ArgumentError, "the message of error number " + n.to_s
    ensure
      $inner += 1
    end
  ensure
    churn
  end
end

$inner = 0
begin
  nested(1)
rescue ArgumentError => e
  puts e.message
end
```

prints `filler string number 3331`, in a plain run at -O0 and -O2. CRuby prints `the message of error number 1`.

After: CRuby's line.

An ensure region whose body is done hands the exception it waits with to the ensure region around it: it pops that region's frame and jumps to its ensure body. The collector keeps what the exception slots hold up to `sp_exc_top`, and the slot the message was read from lies above that once the frame is popped, so the first collection in the outer ensure body freed the message. The hand-on now puts the message and the object in the popped frame's slot, as a landing in that frame would have left them.

Two commits. The first moves the hand-on line, written out three times (`emit_begin`, the region of `Mutex#synchronize`, the loop of `select!` and its kin), into `emit_ensure_exc_hand_on` and changes no C. The second adds the two stores there.

Cost: two stores where an exception passes from one ensure to the next; nothing where none is raised.

Not here: an outer ensure body that enters a begin of its own takes that slot again; "An ensure keeps the exception it holds while its body runs" roots the exception for the body.

Measured on master 26d456ec1: the test is right at -O0 to -O3, with clang and under both stress modes (master: two lines wrong at every level, in a plain run). Under SPINEL_GC_STRESS=2 the regions of `Mutex#synchronize` and of `select!` lose the message on master the same way, with an outer ensure body that allocates nothing; both are right here. The first commit changes the C of no corpus program (6,350 identical). With the second, the C of 29 changes besides the new test, each by the two stores, and they print what they printed (one, tmpdir_expand_usable, fails here on master too); 6,321 are identical. optcarrot's C is unchanged; the scale-test ratios are master's (1.71, 4.73, 6.05, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
