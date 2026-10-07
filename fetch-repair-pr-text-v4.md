Title: A String fetched out of a boxed container and stored back takes its appends

## What this changes

```ruby
h = {}
%w[a b a a].each do |w|
  fresh = !h.key?(w)
  h[w] = h.fetch(w, +"")
  h[w] << "," unless fresh
  h[w] << w
end
p h.to_a
```

prints `[["a", "a,a,a"], ["b", "b"]]` in CRuby and did here until pull request 7462 ("A String handle demanded of a value that later widens is no handle"); since then it prints `[["a", ""], ["b", ""]]`. The Array form (`a[i] = a.fetch(i, +"")`) loses the append the same way, and `concat`, `prepend`, `setbyte`, `slice!` and `reverse!` on such an element raise NoMethodError.

The fetch is a read the append's handle is demanded of, and its own value is boxed. While such a read was typed the handle, the store boxed it as one. That change types it as the boxed value it is, and the store then took the box as it came: a plain String in it stayed a plain String, and the append answered a new String that nothing kept. The store of such a read now lifts the box: a plain String becomes the handle, as before, and any other value passes as the box it is. The read's type stays as that change left it.

Two commits. The second keeps a frozen String out of the lift: it can take no change in place, and a frozen literal taken as the default (`h[k] = h.fetch(k, "none")`) stays the one object it is on master.

Of 1,279 programs that read the stored String back in every way it can be, 130 go from wrong (85) or NoMethodError (45) to right and none that was right changes its answer. `tools/cident.sh`: 6265 identical, 18 differ (9 are the fix beneath; the others are the two new tests and seven that pass before and after, each changed line master's with the `sp_poly_strbuf_lift_unfrozen(` wrap added).

Cost, where a marked element read is stored boxed (callgrind, per store): 9 instructions when the element is a handle already, 13 for a frozen default, and for a plain String that is not frozen a handle and a copy of its bytes, as before that change: 578 instructions per new Hash key and 62 to 106 MB at 400,000 keys.

Left as on master: a Hash with Symbol keys and the block form (`h.fetch(k) { +"" }`) lose the append, and a default kept under another name (`h[k] = h.fetch(k, d)`) is a copy.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the search fix, "A boxed String the program appends to is still a String to include?, casecmp and pack": the lift puts a handle where master has a plain String)
