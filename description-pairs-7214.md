# PR 7214: description edit for head ec96f113 on master ba6317b6

Nine exact replacements against the description as it stands on GitHub (last edited 18:19 UTC, base f0263e6c). Each old string occurs once. Nothing else in the description changes.

Numbers are from `make gate` on ec96f113 (the fourteen commits rebased on master ba6317b6), finished 00:21 UTC on 2026-10-03, `make cident REF=ba6317b6`, and master's own `make scale-test` at ba6317b6.

## 1

Old:

```
`make cident REF=f0263e6c` reports 5670 identical and 14 differing
```

New:

```
`make cident REF=ba6317b6` reports 5675 identical and 14 differing
```

## 2

Old:

```
Nine commits. The first five are fixes
```

New:

```
Fourteen commits. The first five are fixes
```

## 3

Old:

```
each still fails on master at f0263e6c:
```

New:

```
each still fails on master at ba6317b6:
```

## 4

Old:

```
The other four commits are the registry, the keys for the nil narrowing, the keys for the rooting predicates, and the tool.
```

New:

```
The next four commits are the registry, the keys for the nil narrowing, the keys for the rooting predicates, and the tool. The last five answer the review: a decisions log is not written over a file that is not one, `decisions-test` checks how a denied build exits and not only what it prints, the report does not call a build right for matching a wrong one, a key holds the whole of its site and name, and the log check reads only a regular file.
```

## 5

Old:

```
No function over 1,000 lines grows in any of the nine commits
```

New:

```
No function over 1,000 lines grows in any of the fourteen commits
```

## 6

Old:

```
Tests: 5596 pass, 2 fail, 0 error
```

New:

```
Tests: 5601 pass, 2 fail, 0 error
```

## 7

Old:

```
scale-test: work at 4x the program, compiled to C, is 6.31x (limit 6.90)
```

New:

```
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
```

## 8

Old:

```
scale-test: call-shape work at 4x the units, compiled to C, is 4.25x (linear 4.00, limit 4.50)
```

New:

```
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
```

## 9

Old:

```
Rebased on master at f0263e6c.
```

New:

```
Rebased on master at ba6317b6.
```
