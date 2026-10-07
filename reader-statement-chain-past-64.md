<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Page
  attr_reader :text
  def initialize = @text = +"t"
end
pg = Page.new
pg.text << "a" << "a" << "a"     # 65 links in all
p pg.text.size                   # 66 in CRuby, 2 on master
```

64 links are right. The statement arm for an append onto a shared String (`str_mutate_append_bang_arms`) walks 64 links, and a longer chain goes on to the arms that write each link back to the variable the chain stands on. A reader's String has no variable: the first link reached it and the rest went to a copy.

A chain past 64 links that stands on a call is now walked whole by the statement arm, as it is at 2 to 64. What was chosen: a chain that stands on a variable (a local, an instance variable, a global) keeps the arms it had and is master's C byte for byte; master is right there at any length. The compile takes master's time:

| links in the chain | 100 | 200 | 400 |
|---|---|---|---|
| `spinel -c`, master | 0.37 s | 1.42 s | 5.68 s |
| `spinel -c`, this | 0.33 s | 1.47 s | 5.62 s |

Tests: `test/string_reader_statement_chain_long.rb` has chains of 65 to 100 links on a reader, an accessor, a reader written by hand, a reader of a reader, `self.text`, a Struct member and a reader in parentheses, of `<<`, `concat` and interpolated links; nine of its twelve lines differ on master. The other three are 64 links on a reader and a longer chain on a local, right before.

Generated C against master (`make cident REF=8578e3fb`): `6354 identical, 1 differ, 0 refusal changes` (the new test). `tools/refusals.sh` passes (534 records). optcarrot's generated C is byte-identical. Programs, with CRuby 3.3.6 as the reference: 720 statement chains of 2 to 400 links (15 roots, 6 kinds of link). The 270 that lose links on master, every chain of 65 links or more on a reader, an accessor, a reader written by hand, a reader of a reader, a `&.` reader, a Struct member, `self.text`, `hs.first.text` and a reader in parentheses, are right. The 402 that are right print the same. 48 are wrong before and after, at every length: a String a class method hands out of a class variable is a copy on master, another fault.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers and Strings)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
