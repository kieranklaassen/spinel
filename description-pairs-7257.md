# PR 7257: description edit for head c40c5a07 on master ba6317b6

One exact replacement. The old string occurs once in `compiler-under-asan.md` on this branch, the text the description was opened with; the description as it stands on GitHub was not read for this file. Nothing else in the description changes.

## 1

Old:

```
Three commits, the two fixes and then the lane that found them.
```

New:

```
Five commits: the two fixes, the lane that found them, and two for the review of the lane's script (it finds its job count without nproc, and a compiler killed by a signal without a report ends the run with status 2).
```
