<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = "café".codepoints.pack("U*")
p s == "café"            # false          CRuby: true
p s.size, s.encoding     # 5, ASCII-8BIT  CRuby: 4, UTF-8
```

Array#pack marked every answer BINARY. CRuby answers UTF-8 where the template holds a U and no directive but U, m, M and u, so a String built from codepoints was not the String it spells: `==`, `size`, `chars`, `[-1]`, `inspect`, `ljust` and a Hash key all read bytes. The four pack entries in `lib/sp_pack.c` now ask the template before they mark; any other template (`"UC"`, `"CU"`, `"U n"`, `"Ux"`) is bytes in CRuby too and is marked as before.

Test: `test/pack_u_answers_text.rb`; 30 of its 50 lines differ on master. Checked on 574 generated programs (13 Arrays by 36 templates, and 106 uses of the answer) built with gcc and with clang and run at `SPINEL_GC_STRESS` unset, 1 and 2: 144 that were wrong are right, and none that is right on master changes. No generated C changes. Every pack pays a test of its template's first directive, 27 instructions a call for `pack("C*")` (callgrind over a million calls); `pack("U*")`, whose template is walked, pays 61.

Left as on master: a template of `m`, `M` or `u` alone, or an empty one, is US-ASCII in CRuby and ASCII-8BIT here; a `"\r"` or a `#` comment in a template is skipped by CRuby and makes bytes here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
