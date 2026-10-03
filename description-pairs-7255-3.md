# PR 7255, third review round: "Resolve the alias before rewriting `next`"

CodeRabbit, src/analyze_desugar.c:6740, id 4171465764, Minor, raised 03:07 UTC on 2026-10-03 against 75c390c2.

Verdict: REAL, a regression of this PR. FIXED by one added commit, 5e7e8d41, with two tests. The second reading then found one more route (a name an `each` over literals puts together), also a regression, FIXED by a seventh commit, af34c8c3, with one test: see "Seventh commit" below. Head of `pr/next-in-run-once-blocks` is af34c8c3, seven commits on ba6317b6, final unless the second reading finds something.

## What was built

Builds: master = upstream 62b01c7f; old = 75c390c2 (on ba6317b6) and 75c390c2 merged with 62b01c7f, which agreed on every program; fix = 5e7e8d41 (on ba6317b6) and 5e7e8d41 merged with 62b01c7f (6ca67872 locally), which agreed on every program. CRuby is 3.3.6 here with `--enable-frozen-string-literal`. Programs are in `repro/alias/` (a01 to a23, b01 to b23, c1 to c3, cr1 and cr2 the Mac's two, reply1 and reply2 the two the reply describes); every one has a `next` in a `define_method` or `define_singleton_method` block except a19 and a20. "no build" is a C compiler error, "refused" a `spinel:` message.

Fifteen that answer as CRuby on master and broke at 75c390c2. With the fix all fifteen answer as on master.

| program | shape | master | old | fix |
|---|---|---|---|---|
| a06 | `alias define_method my_dm` in the class, call in an instance method | `[1, :after]` | no build | as master |
| a07 | the same by `alias_method :define_method, :my_dm` | `[1, :after]` | no build | as master |
| a17 | alias in the superclass, call in a subclass's method | `[1, :after]` | no build | as master |
| a22 | aliased method yields instead of `b.call` | `[1, :after]` | no build | as master |
| b01 | `alias_method "define_method", "my_dm"`, Strings | `[1, :after]` | no build | as master |
| b04 | `define_method(:define_method, instance_method(:my_dm))` | `[1, :after]` | no build | as master |
| b05 | `private alias_method :define_method, :my_dm` | `[1, :after]` | no build | as master |
| b06 | `alias define_method my_dm if true` | `[1, :after]` | no build | as master |
| b07 | alias in an included module | `[1, :after]` | no build | as master |
| b16 | alias in `class << self`, call in a class method | `[5, :after]` | no build | as master |
| b17 | def and alias both in `class << self`, call in a class method there | `[5, :after]` | no build | as master |
| a09 | `alias define_singleton_method my_dm` in `class << self`, call in the class body | `5`, `:done` | builds, prints nothing, exit 0 | as master |
| b14 | the same by `alias_method`, Symbols | `5`, `:done` | builds, prints nothing, exit 0 | as master |
| b15 | `alias define_method my_dm` in `class << self`, call in the class body | `5`, `:done` | builds, prints nothing, exit 0 | as master |
| b21 | singleton alias in the superclass, call in a subclass body | `5` | builds, prints nothing | as master |

The eleven "no build" are all "returning 'long long int' from a function with return type 'sp_PolyArray *'": the `return` left in the block is read as the enclosing method's.

One more changed and is back as on master, though master is not CRuby's there: a10, a top-level `alias define_method my_dm` (CRuby `:m`, since main has its own `define_method`; master `3`; old builds and prints nothing; fix `3`).

The other thirty did the same on master, old and fix:

- Answer as CRuby on all three: a11 (`A.define_method` with a receiver), a13 (an `each` over literals), a18 (statement, value unused), a19 and a20 (no `next`), a21 (the call is the method's last statement), b02, b03 and b20 (a `define_method` or `define_singleton_method` named by `define_method` with a block), b13.
- No build on all three: a08 (instance-level `alias define_singleton_method`, "invalid initializer"), b22 (a keyword parameter, `lv_k` undeclared).
- Refused on all three: a01 to a05, a12, a14, a16, a23 (my programs called `Class#name` in the block, a NameError; b14 to b17 are the same shapes without it), a15 and b08 and b10 ("unsupported call"), b09 (`send(:alias_method, ...)`), b11 and b12 (`method_missing` is not dispatched), b18 and b19 (`singleton_class`), b23 (singleton class of an object).

The Mac's program (a block parameter, `alias_method` or `alias` in `class << self`): here too it fails the same on master and with the fix, `lv_x` undeclared (gcc's wording). Not a regression and not changed.

What the wider check gives back, measured: c1 (a `define_method` block with a `next`, plus `A.respond_to?(:define_method, true)`) and c2 (plus `p "define_method"`) build at 75c390c2 and now do not, as on master ("continue statement not within a loop"). c3 (`:define_methods` and `"define_method "`, neither spelling the name) still builds. The description says so under "Left as they were".

## The fix

`method_body_next_to_return` (src/analyze_desugar.c) already left every such block alone in a program with a DefNode named `define_method` or `define_singleton_method`. The same loop now also stops at a SymbolNode or StringNode whose text is either name (`sym_or_str_literal`, already in the file). The names of an `alias` are SymbolNodes. The loop's two lines became one and the comment above it grew by two; no function grew.

Not resolved per call, for the reason the fourth and fifth commits found: the class table is still being filled where the rewrite runs.

Checks on 5e7e8d41: `make cident REF=75c390c2` 5686 identical, 2 differ (the two new tests), 0 refusal changes; `infer-test`, `reject-test`, `collect-errors-test` pass on the branch; `make gate-props` passes on the merge with 62b01c7f (378 refusal records; scale-test 1.74 / 4.82 / 6.29 / 4.24, and master 62b01c7f gives the same four); the two new tests, `test/next_in_run_once_block.rb` and `test/define_method_user_defined_block_next.rb` print their `.expected` plain and under `SPINEL_GC_STRESS=1` and `=2`, on the branch and on the merge; both new tests pass on master 62b01c7f and do not build at 75c390c2. No full `make gate` here: that is the Mac's.

## Seventh commit: a name put together at compile time (af34c8c3)

The second reader's probe `repro/alias/unroll_name.rb`: CRuby `[[:a, 1], :after]`; master 62b01c7f builds it and prints the same; 5e7e8d41, unmerged and merged with 62b01c7f, does not build it ("returning 'long long int' from a function with return type 'sp_PolyArray *'"). `unroll_name_plain.rb`, the same with a ternary for the `next`, answers right on all three. So a regression.

Programs e01 to e18, f01 to f07, g01, g02, h01 in `repro/alias/`, each on master 62b01c7f, on 5e7e8d41 (e01 to e18, f01 to f07, g01 and g02 unmerged, h01 merged with 62b01c7f) and on af34c8c3 unmerged and merged with 62b01c7f (71fbd3a8 locally), which agree on every program. All but g01 and g02 have `def run; v = define_method(:a) { next 1 if ARGV.length == 0; 2 }; [v, :after]; end` in the class; g01 and g02 are a class U whose `next` is in the unrolled block itself.

| program | how the class gets its `define_method` | master | 5e7e8d41 | af34c8c3 |
|---|---|---|---|---|
| e01 | `[:method].each { \|v\| define_method("define_#{v}") { } }` | `[[:a, 1], :after]` | no build | as master |
| e02 | the same with `:"define_#{v}"` | as CRuby | no build | as master |
| e03 | `"#{v}_method"` over `[:define]` | as CRuby | no build | as master |
| e06 | `"de#{v}od"` over `[:fine_meth]` | as CRuby | no build | as master |
| e15 | `"#{v}efine_method"` over `[:d]` | as CRuby | no build | as master |
| e14 | `"define_#{v}"` over `[:method, :other]` | as CRuby | builds, prints nothing | as master |
| h01 | e01 written with `do` and `end` | as CRuby | no build | as master |
| e04 | `"#{v}"` over `["define_method"]` | as CRuby | as master (the element is a whole literal) | as master |
| e05 | `define_method(v)` over `[:define_method]` | as CRuby | as master (the same) | as master |
| e07 to e13, e16 to e18 | adjacent literals or an interpolated name outside an `each`, `alias_method` with an interpolated Symbol, with `("define_" + "method").to_sym`, with adjacent Strings, with a heredoc, with a constant, in an `each`; `"define_" + v.to_s`; `"define_method#{}"` | refused, "unsupported call" at the `define_method` in `run` | the same | the same |

f01 to f07 are for the matcher: `"#{v}d"` over `[:define_metho]`, `"de" "fine_#{v}"`, `:"de#{v}thod"`, `"#{v}_#{"method"}"`, and `"d#{v}fin#{v}_m#{v}thod"` over `[:e]` answer as CRuby on master and on af34c8c3 and do not build at 5e7e8d41 (the same C error); `"define_#{v}_method"` over `[:singleton]` (no `define_method` is made, CRuby raises NoMethodError) and `"define_#{v}#{}"` are refused on all three. g01 (`"m_#{v}"`, `"defined_#{v}"`, `"#{v}_define_method_x"`, with a `next` in the first) does not build on master and builds and answers as CRuby at 5e7e8d41 and on af34c8c3: such names cannot spell either name and keep the rewrite. g02 (`define_method("#{v}") { ... next ... }` over `[:a, :b]`) does not build on master nor on af34c8c3: a lone `#{}` can spell anything, so the check stands down. It built and answered as CRuby at 5e7e8d41; that is the price, and the description's "Left as they were" now says it.

The fix. In the same loop of `method_body_next_to_return`, a CallNode named `define_method` (any receiver) whose first argument is an InterpolatedStringNode or InterpolatedSymbolNode stops the rewrite when its parts can spell `define_method` or `define_singleton_method` (`dm_interp_name_may_be_dm`, `interp_pieces_spell`): a part that is a whole String or Symbol literal must match in order, at the place the name has reached when no `#{}` stands directly before it and anywhere after one (every occurrence is tried), and any other part (an EmbeddedStatementsNode, a nested interpolation) is any text. Two static helpers, 13 and 12 lines; `method_body_next_to_return` grew by two lines.

### Every way the compiler comes to know a method by a name the program chose

From a read of the sources by a worker (it built nothing), which I checked against the code for routes 1 to 4 and for dm_eval_name; line numbers are af34c8c3's tree, src/.

What the check sees: (a) a DefNode named either name, (b) a SymbolNode or StringNode whose whole text is either name, (c) a `define_method` call whose interpolated first argument can spell either.

1. `def`: walk_scope (analyze_scope.c:1133) and sclass_walk_stmt (:998) read DefNode "name". Seen by (a).
2. `define_method` / `define_singleton_method` with a literal name: analyze_scope.c:1180-1220 and dm_defined_name (:802) read SymbolNode "value" or StringNode "content". Seen by (b).
3. The each-unroll: collect_dm_each_unroll (analyze_scope.c:580-656), name from dm_eval_name (:530-564), its only caller. dm_eval_name evaluates: a StringNode or SymbolNode (seen by (b)); a LocalVariableReadNode that is the loop variable, which becomes the element's text, the element being an IntegerNode, StringNode or SymbolNode (a whole literal, seen by (b); an Integer spells neither name); an EmbeddedStatementsNode with exactly one statement, recursively; an InterpolatedStringNode or InterpolatedSymbolNode, the concatenation of its parts, recursively, which includes adjacent literals. It returns NULL, and the unroll gives up, for any other local, any call (`v.to_s`, `to_sym`, `+`), a constant, parentheses, a `#{}` with more than one statement. So a composed name is always an interpolated node that is the call's first argument, with whole-literal parts and embedded parts: seen by (c), where every non-literal part counts as any text.
4. `alias new old`: register_aliases_body (analyze_scope.c:2839) reads "value" of the new name's node, a SymbolNode; an interpolated one gives NULL and is skipped. `alias_method :new, :old`: :2859-2866, both SymbolNodes. `alias_method "new", "old"`: desugar_alias_method_string_names (analyze_desugar.c, called at analyze.c:27629) retypes the two StringNodes into SymbolNodes in place. `define_method(:m, instance_method(:x))` becomes that alias_method with the same literal. All seen by (b).
5. What is a DefNode before the first call of the check (desugar_define_method_keywords, at analyze.c:27670): a keyword `define_method` (name from the Symbol or String literal), accessors turned into defs (attr_as_def, desugar_handle_attr_accessor, desugar_singleton_attr), alias-to-def desugars, FFI `attach_function` / `attach_variable`, the text of a static `class_eval "..."` (parsed and imported at analyze.c:27551, also when stamped out per element of a constant Array), and, before the node table exists, `def_delegator(s)` and class-body macros rewritten to `def` in the source text (spinel_parse.c, sp_macro.c). Seen by (a); most also by (b).
6. Name tables that are no scopes: attr readers and writers (register_attr_call, SymbolNode only), Struct and Data members (SymbolNode), builtin FFI declarations (Symbol or String). Seen by (b).
7. Copies only, no new name: include, extend, `obj.extend`, prepend, module_function, `extend self`.
8. Names the compiler makes itself and that cannot be either name: setters `x=`, `Name_new` / `Name_get_f` / `Name_set_f` of an ffi_struct, the six `compiler_state_*` methods, and internal ones (`f__redefN`, `f__mainN`, `base#__condN`, `name#pf`, `__to_enum_<m>`, `__bam_<tag>`, `__inc N name`, `__prep_N_name`).
9. Not routes: `method_missing` is never dispatched to; `send(:m, ...)` only renames the call, after walk_scope; `instance_eval` with a String is not grafted; a computed `alias_method` name registers nothing.

Not determined by the read: whether a receiverless call inside a builtin FFI module reaches the names of `ffi_func` / `native_func` declarations (those are whole Symbol or String literals, so (b) sees them either way); the full set of expressions sp_macro.c evaluates (its output is source text parsed with the rest, so (a), (b) or (c) sees a name in it as in any other source); and it found no pass that removes the last DefNode or literal spelling a name between the passes, but did not prove that for every pass after walk_scope. The second reader narrowed this: the loop scans every node of the table, linked into the tree or not, so only a pass that retypes a node in place or rewrites its name in place could hide one; the two passes that retype a String name keep its text as a Symbol (analyze_desugar.c:6694 and :10505); the renames of a def read so far (analyze.c:26713 and :27191, analyze_desugar.c:7374) each leave a def of the old name and run before the first call; and it matters only between the first call of the check (analyze.c:27670) and the one later one, the re-walk in make_yield_proc_forms (analyze.c:22191, called at :28455). For the other sites that retype a node or rewrite a name in place it stays unproven.

Checks on af34c8c3: `make cident REF=5e7e8d41` 5688 identical, 1 differ (the new test), 0 refusal changes; `infer-test`, `reject-test`, `collect-errors-test` and `make gate-props` pass on the branch, and `make gate-props` on the merge with 62b01c7f (378 refusal records; scale-test 1.74 / 4.82 / 6.29 / 4.24, master's four); the three new tests and the two older ones print their `.expected` plain and under `SPINEL_GC_STRESS=1` and `=2`, on the branch and on the merge; `test/define_method_unrolled_name_block_next.rb` passes on master 62b01c7f and does not build at 5e7e8d41 merged with it; the 51 programs of the alias round do on af34c8c3, branch and merge, what they did on 5e7e8d41 (50 as master, c3 builds). Seven commits, one trailer each, scan clean. No full `make gate` here.

## Master 62b01c7f

75c390c2, 5e7e8d41 and af34c8c3 all merge cleanly with 62b01c7f, alone and together with 7238 (cd3ddfe2) and 7256 (a9f9f669). The five commits since 6535952f touch lib/spinel_rt.h, src/codegen*.c and src/codegen_internal.h, packages/ffi and packages/fiddle and add seven tests under test/ and packages/*/test: nothing under test/reject or test/collect, and not test/collect/refusals.expected. `collect-errors-test` passes on the merge (378 records).

## Reply

`review-7255-reply-3.md`, for the thread of comment 4171465764.

## Description pairs, against pr2-body.md as it stood at 03:09 UTC (sha256 2a43e94f...)

Pair 1, in the `define_method` bullet. Old:

> and so does every such block in a program that defines a `define_method` or `define_singleton_method` of its own (`test/define_method_user_defined_block_next.rb`).

New:

> and so does every such block in a program that has a def named `define_method` or `define_singleton_method` (`test/define_method_user_defined_block_next.rb`), or that spells either name whole in a Symbol or String literal, as an `alias` or `alias_method` written with that name does (`test/define_method_alias_block_next.rb`, `test/define_method_alias_string_block_next.rb`), or that has a `define_method` call whose interpolated name can spell either, as an `each` over literals can put one together (`test/define_method_unrolled_name_block_next.rb`).

Pair 2, in the `make cident` paragraph. Old:

> the compiler's sources at the head are the third commit's. optcarrot's C is byte for byte the same, 12,255 lines. `reject-test` and the gate's property checks pass here, on the branch and merged with 6535952f (scale-test 1.74 / 4.82 / 6.29 / 4.24, master's four); the full `make gate` is below.

New:

> the compiler's sources at the fifth are the third commit's. The sixth against the fifth: 5686 identical, 2 differ, the two alias tests, which the fifth does not build. The seventh against the sixth: 5688 identical, 1 differ, `test/define_method_unrolled_name_block_next.rb`, which the sixth does not build. optcarrot's C is byte for byte the same, 12,255 lines. `reject-test` and the gate's property checks pass here, on the branch and merged with 62b01c7f (scale-test 1.74 / 4.82 / 6.29 / 4.24, master's four); the full `make gate` is below.

Pair 3, in "Left as they were". Old:

> in a program that defines a method of either name anywhere: the block is left as it is

New:

> in a program that has a def of either name anywhere, or a Symbol or String literal spelling either name whole anywhere, or a `define_method` call whose interpolated name can spell either, a `#{}`, or an adjacent literal that holds one, counting as any text: the block is left as it is

Pair 4, the gate block: the Mac's lines for its full gate on af34c8c3 merged with the master it runs on.

pr2-body.md now holds pairs 1 to 3 (the gate block is still the placeholder GATE_LINES).
