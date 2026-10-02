<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`puts "issue #12"; p [1, 2, 3].partition { |v| v > 1 }` raises NoMethodError on master, where CRuby prints `[[2, 3], [1]]`. The builtin splices are decided from the resolved text before the parse, and `sp_source_mentions_method` took any `#` earlier on the line for the start of a comment, so the call behind it named nothing and `builtins/enumerable.rb` was left out. An interpolation's `#{` did the same (`puts "n=#{n} parts=#{a.partition { |v| v > 1 }}"`), and so did the `#{kind}` of a class_eval template (`def #{kind}_parts = @list.partition { |v| v > 2 }`).

The other way round, `strstr(source, "define_finalizer")` spliced `builtins/object_space.rb` into a program that only prints the word, and the file is analysed with the program: `test/poly_index_not_proc.rb` is refused ("a String is passed through a proc or Method read out of a slot ...") once `puts "this program does not call define_finalizer"` stands ahead of it. `strstr(source, "break")` spliced `builtins/enumerator.rb` for the word in a comment.

Where the text is a comment, and whether a word in it is code, is now asked of prism (`sp_src_lex_of`): its comment list, and through the lex callback whether `break` was lexed as the keyword and `define_finalizer` as an identifier, inside an interpolation too. It reads a text once, and only when a splice has to ask: a name with no `#` before it on its line is decided as before, without it. A name inside a string still counts as a mention, since a template's text is code and a false positive costs the parse of a small file. The finalizer API and the Enumerator are spliced for the token. A program that evaluates a string (`eval`, `class_eval`, `module_eval`, `instance_eval`), or one prism could not parse, keeps them wherever the word is spelled: a class_eval template is a string until `sp_expand_class_macros` reads it, after the splices.

Measured on 0d370b71, master against this branch: of the 5,473 programs in `test/` the generated C of 5,465 is byte for byte the same, and so is that of the 64 benchmarks and of optcarrot. Four tests gain `builtins/enumerable.rb` for a name that stood behind a `#{` (`sp_net_poll_grow`, `thread_concurrent_alloc`, `thread_kill_poly_receiver`, `inlined_call_options_hash_positional`) and four lose `builtins/enumerator.rb`, having `break` only in a comment (`endless_method`, `hash_param_each_kv_weak_default`, `map_recv_emitted_once`, `thread_alloc_scaling`); all eight still pass, under `SPINEL_GC_STRESS=1` too. Compiling optcarrot takes 0.39% more instructions under callgrind (6,573,475,027 to 6,598,869,710), which is prism reading its text; `bm_ao_render`, which has no `#` ahead of a builtin's name, takes 188 more.

Three tests. `builtin_splice_hash_in_literal` puts every call behind a `#` that starts no comment (a string, an interpolation, a %w list, a regexp, a character literal, a heredoc, a class_eval template) and raises NoMethodError on master. `object_space_word_in_string` is the refusal above, reduced to 17 lines. `object_space_finalizer_class_eval` passes on master and holds the rule for a program that evaluates a string: without it the finalizer in the template is refused.

What stays as it was: the Gem, RbConfig, Set and IO::Buffer splices keep their own scans. A builtin named only by a Symbol (`[[1, 1, 2]].map(&:tally)`, `[1, 1, 2].send(:tally)`) is still not spliced and still raises NoMethodError: `sp_source_mentions_method` passes over a name after `:`, which is another rule than the comment's, and it is not changed here.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 where this was built; the three print only strings, symbols, integers, nil and arrays of them)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
