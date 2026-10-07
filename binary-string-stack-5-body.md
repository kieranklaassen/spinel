<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
data = "caf\xC3\xA9".b              # what File.binread answers
buf = +""
data.each_char { |c| buf << c }
p buf.encoding                      # UTF-8, CRuby ASCII-8BIT
p buf.size                          # 4, CRuby 5
p buf == data                       # false, CRuby true
```

`<<` and concat keep the receiver's encoding where the operand's is compatible. A BINARY operand holding a byte past ASCII, appended to text that holds no character past ASCII, makes the receiver binary in CRuby, as `+` does; here the receiver stayed UTF-8. `sp_str_append_grow` and `sp_String_append_bin` already handle the other direction (text past ASCII appended to ASCII-only bytes); each gets the mirror of that test, and the receiver is marked in place, so an alias sees it.

This closes the four beneath it. They make the pieces of a binary String binary, and a program collects pieces in a buffer: without this commit `buf << c` in the loop above, `out << line.chomp` over each_line, `out << word` over scan or split and `out << data.upcase` all give a UTF-8 String with a character count again.

Test: `test/binary_string_appended_to_text.rb`; 6 of its 19 lines differ on master. The cost is the test of the operand's mark for a receiver that is not marked: 6 instructions an append (callgrind, a million appends). No generated C changes.

Stands on "The characters of a binary String are binary Strings".

Left as on master:

- Bytes appended to text that holds a character past ASCII (`buf = +"é"; buf << data`) raise Encoding::CompatibilityError in CRuby; the receiver stays text here.
- `replace` on a local and a Symbol do not carry the mark: after `q = +"q"; q.replace(data)`, `q.encoding` is UTF-8, and so is `data.to_sym.to_s.encoding`.
- `format("%s", data)` answers UTF-8.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
