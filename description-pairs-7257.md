# PR 7257: description edit for head bf8e544b on master ba6317b6

One exact replacement. The old string is the new string of the pair this file held before (three commits to five), which the thread that owns the PR reports as already applied to the description on GitHub; the description as it stands on GitHub was not read for this file. Nothing else in the description changes.

## 1

Old:

```
Five commits: the two fixes, the lane that found them, and two for the review of the lane's script (it finds its job count without nproc, and a compiler killed by a signal without a report ends the run with status 2).
```

New:

```
Seven commits: the two fixes, the lane that found them, and four for the review of the lane's script (it finds its job count without nproc; a compiler killed by a signal without a report ends the run with status 2; the last line counts the programs left uncompiled without a report; no program at all is an error).
```
