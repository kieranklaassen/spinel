# PR 7257: description edit for head a1acf45d on master baa1990f

One exact replacement. The old string is the new string of the pair this file held before (five commits to seven), which the session that edits the description last reported as what the description on GitHub says; the description as it stands on GitHub was not read for this file. Nothing else in the description changes.

## 1

Old:

```
Seven commits: the two fixes, the lane that found them, and four for the review of the lane's script (it finds its job count without nproc; a compiler killed by a signal without a report ends the run with status 2; the last line counts the programs left uncompiled without a report; no program at all is an error).
```

New:

```
Ten commits: the two fixes, the lane that found them, and seven for the review of the lane's script (it finds its job count without nproc; a compiler killed by a signal without a report ends the run with status 2; the last line counts the programs left uncompiled without a report; no program at all is an error; each program's log is named by its place in the list, so two paths cannot share one; the counts print without wc's padding; the programs go to xargs as NUL-ended items, and a run that tried fewer programs than the list holds ends with status 2).
```
