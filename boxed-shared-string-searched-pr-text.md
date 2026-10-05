Title: A boxed String the program appends to is still a String to include?, casecmp and pack

## What this changes

```ruby
h = { "k" => +"ab", "n" => 1 }
h["k"] << "c"
p %w[abc cd].include?(h["k"]), "ABC".casecmp?(h["k"]), [h["k"]].pack("a4")
```

prints `true`, `true` and `"abc\x00"` in CRuby and `false`, `nil` and `"\x00\x00\x00\x00"` on master (4d56c1573). Without the append all three are right.

The append makes the Hash's String a shared handle, and the box around it then carries the handle where it carried the bytes. A String Array's `include?`, `member?`, `index`, `find_index`, `rindex` and `delete`, a String Range's `include?` and `cover?`, `casecmp` and `casecmp?`, and the string directives of `Array#pack` each ask the box whether its tag is a String's, and the handle's is not: the search missed, `casecmp` answered nil and `pack` wrote an empty String. The emitters now read the argument through `sp_poly_strbuf_deref`, as `String#==` does for a boxed argument, and pack's element reader takes the handle's bytes and length. A box that holds no String answers as before.

**Checked** on 4d56c1573 with gcc, against CRuby 3.3.6 run with `--enable-frozen-string-literal`, each program at `SPINEL_GC_STRESS` unset, 1 and 2:

- 1,279 programs: a String out of a Hash or an Array that also holds an Integer, appended to elsewhere in the program, never appended to, or fetched and stored back, then read, compared, or handed as the argument to 47 String-taking forms (Array search, set operations and sort, String comparison, search and building, Hash keys and values, `format` and `pack`, Regexp, IO, File, method, block and lambda arguments). 1,144 give byte-identical C and call no `pack`; the other 135:

  | 4d56c1573 | this branch | programs |
  |---|---|---|
  | wrong | right | 36 |
  | right | right | 91 |
  | wrong | wrong | 8 |

  No program right on master is wrong on this branch, and no C error or raise becomes an answer. The 8 are other faults, under "Left alone".
- `tools/cident.sh 4d56c1573` (test/, benchmark/ and packages/*/test; optcarrot was not in the corpus where this was measured): 6115 identical, 8 differ, 0 refusal changes. The 8 are the new test and seven tests that pass before and after: `codegen_settled_operand_types`, `fallback_block_gets_the_missing_key`, `inline_recv_hold_r2`, `str_array_delete_boxed_needle`, `str_array_include_nil_arg`, `string_comparison_to_str`, `string_slice_casecmp_succ`. Every changed line is master's line with the `sp_poly_strbuf_deref(` ... `)` wrap added; `delete` with a block reads the wrapped value from a temporary of its own.
- pack's change is in the runtime, so the C does not show it: the 59 programs of the corpus that call `pack` pass before and after.
- The wrap is two compares for a box that holds no handle. `%w[ab cd].include?(h["k"])` 300,000 times is 97,258,988 instructions before and 98,759,002 after (callgrind), 5 per call; `"CD".casecmp?(h["k"])` is 49,856,941 and 52,556,955, 9 per call.
- `tools/refusals.sh`: pass (426 records). `make reject-test`: pass.

**Left alone**, each as on master:

- `(h["k"]..h["k"]).to_a` prints `[0]` for boxed ends, a handle or not (7 of the 8), and `"ab".equal?(h["k"])` is false for a literal kept in the Hash (1).
- `"ab".between?(h["k"], h["k"])` does not compile, for a handle or a plain String in the box.

No function over 1,000 lines grows: `emit_kind_array_call` 797 to 795; `emit_call_body` is untouched. `lib/spinel_rt.h` is untouched.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (3.3.6 here; the test prints no Hash)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
