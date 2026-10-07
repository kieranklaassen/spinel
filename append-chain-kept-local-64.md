<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"b"
t = s << "a" << "a" << "a"     # 64 links in all
t << "!"
p s.size, t.equal?(s)          # 66 and true in CRuby; 65 and false on master
```

63 links are right. `s << a << ...` is `s` itself, so `t` names the same String, and the walk that says so for a kept chain (`an_strbuf_alias_source`) gave up after 64 steps: from 64 links `t` took a copy, and what was appended through `t` never reached `s`.

The walk has no limit now; every step goes down to a child, so it ends where the chain does. What was chosen, to keep what master gets right:

- One method keeps the 64: one that holds a pattern match or a Regexp match that writes named captures. A binding onto `t` there builds only where `t` is a copy, so naming `s` would lose a program that is right.
- From 64 links the write emits one append a link on `s`'s handle. The value form a shorter chain keeps nests a statement expression a link, and clang stops at 256 levels, where a chain of 300 links kept and only read builds on master.

With `t` the same String, `t += "x"` after the chain is the write the pull request this depends on compiles; without it master's refusal of that write would reach a chain of 64 links, which compiles today on the copy.

The compile takes master's time:

| links in the chain | 100 | 200 | 400 |
|---|---|---|---|
| `spinel -c`, master | 0.33 s | 1.24 s | 4.75 s |
| `spinel -c`, this | 0.34 s | 1.13 s | 4.56 s |

Left as on master: a chain of 65 links or more that is a `begin` block's value or a method's last expression is still a copy to the local that takes it.

Tests: `test/string_append_chain_kept_long.rb` has kept chains of 64 to 300 links: `<<` and `concat` links, a String a method has appended to, a chain in a method with interpolated links, `+=` after the chain, and 300 links, which clang builds; eleven of its eighteen lines differ on master. The last two are 63 links, right before.

Generated C against master, with the pull request this depends on beneath (`make cident REF=8578e3fb`): `6354 identical, 1 differ, 1 refusal changes` (the new test; the refusal change is that pull request's test). `tools/refusals.sh` passes (542 records). optcarrot's generated C is byte-identical. Programs, with CRuby 3.3.6 as the reference and the pull request this depends on as the base: 1,410 around a kept chain of 2 to 600 links (uses of the kept local, shapes of chain, and patterns and named captures in the same method). 136 that are wrong are right. 17 that are wrong are refused by name, as they are at 2 to 63 links: the chain as an Array element, a Hash value, a pushed value or a block's value that is then appended to through the container. The other 1,257 are the same: 944 right, 152 wrong, 142 that do not build and 19 refused. With clang, of 125 chains of 64 to 330 links, 30 that are wrong or do not build are right and the rest are the same.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers, Strings, true and false)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "+= on a String local that is also appended to is compiled"
