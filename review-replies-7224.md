# matz/spinel PR 7224: answers to the review of 2026-10-02 17:33 UTC

New head: 086fbbdd64246e15e4628549bb2ea5af712575eb (was 8f783875). Two added
commits, no amend, no rebase; merges cleanly with master 58f467d5. Both touch
only `tools/literal_probe.rb`.

## Finding 1, tools/literal_probe.rb:501 (Major): fixed in 00c80450

Real. Reproduced by making the control fail to compile on a later pair: the
pairer kept the regions of the earlier control and `compare` raised
`NoMethodError: undefined method 'byteslice' for nil`.

Reply for the review thread:

> Right, and reproduced: a control that stops compiling during reduction left
> `at` holding the regions of the control before it, and the compare raised
> NoMethodError on nil. Fixed in 00c80450: `at` is set either way, so the pair
> is reported as a finding of class `control`, and a run that raises is now
> written as that run's result instead of ending the probe.

## Finding 2, tools/literal_probe.rb:761 (Minor): fixed in 086fbbdd

Real. `--timeout 0` killed every compile, left every program out as one that
does not compile in time, and ended with status 0.

Reply for the review thread:

> Right: `--timeout 0` left every program out and ended with status 0, which
> says no finding. Fixed in 086fbbdd: it is refused with the same message and
> status 4 as `--bytes` and `--jobs`, as order_probe does for its own.

## PR description

No number changed: an operand pass over 543 tests reports the same 47 programs
in 7 families before and after, and no saved run has a tool error.

One optional pair, so the gate note stays true with three commits:

old: `Run on this branch at 8f783875, which is 5ee16b74 plus this commit.`

new: `Run on this branch at 8f783875, which is 5ee16b74 plus the first commit; the two review commits after it (00c80450, 086fbbdd) change only tools/literal_probe.rb, which the gate neither builds nor runs.`
