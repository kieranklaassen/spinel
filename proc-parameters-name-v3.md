<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`Proc#parameters` printed the compiler's slot name for a parameter the body assigns, in a plain run:

```ruby
p lambda { |k| k = k + 1; k }.parameters           # [[:req, :k]] in Ruby; [[:req, :k__bpin]] on master
p proc { |k, j| k = k.to_s; k + j.to_s }.parameters  # [[:opt, :k__bpin], [:opt, :j]] on master

class Box
  define_method(:bump) { |k| k = k + 1; k }
end
p Box.new.method(:bump)                             # #<Method: Box#bump(k__bpin) ...> on master
```

A block parameter the body assigns becomes an ordinary local fed from a renamed parameter (`desugar_reassigned_block_params`, `src/analyze_desugar.c`: `|k|` becomes `|k__bpin|` with `k = k__bpin` first). The renamed slot was the name `Proc#parameters` interned and `Method#inspect` rendered.

The pass now records each slot name with the length of the name it stands for (`reassigned_param_written_len`). `param_public_name` (`src/codegen.c`) and the `Method#inspect` renderer (`src/codegen_call_method.c`) print the name written, and the two places that put a parameter's name in the symbol table ahead of emission (`src/analyze.c`) put that name there. A slot that also carries the shadow rename's suffix (`k__bpin__bp17`, under an outer local `k`) is read the same way.

So that no name the program wrote is taken for a slot, a slot name steps past a name the program itself uses. That also cures a wrong answer:

```ruby
k__bpin = 5
p lambda { |k| k = k + 1; k + k__bpin }.call(1)    # 7 in Ruby; 3 on master
```

A name of any length is printed whole. `param_public_name` copied the name into 128 bytes and cut it at 127; with a slot read through it, a parameter of 128 bytes or more that the body assigns answered the empty Symbol. The buffer now grows to the name. That also cures a long name that is only renamed under an outer local of the same name, which printed as the empty Symbol on master.

`test/proc_parameters_reassigned_name.rb` prints the parameters of a lambda, a proc and a lambda with an optional, a rest and a post parameter, under `parameters(lambda:)` too, one under an outer local of the same name, one beside a local spelled like a slot, `Method#inspect` of a `define_method` block, and an assigned parameter of 129 bytes. On master (ab9b925aa, Linux x86-64, gcc and clang) 11 of its 19 lines differ from Ruby's in a plain run; with this change none does.

Measured with both compilers built on ab9b925aa:

- 41 programs for every place I found that prints a parameter's name (`parameters` on each way to make a proc, through a local, nested, curried, composed, `lambda(&f)`; `Method#inspect`; `defined?`; `binding.local_variable_get`; a lambda's ArgumentError), judged by ruby 3.3.6: 15 wrong on master are right with this change, 10 are right on both, 16 are wrong on both for other causes, and none is right on master and wrong with it. One of the 16 prints `[:opt]` for a destructured group where 3.3.6 prints `[:opt, nil]`.
- 50 programs with a name of 40 to 300 bytes (assigned, under an outer local, both, in a `define_method` block, beside a local spelled like the slot): 9 are right on master and 30 with this change, and none is right on master and wrong with it. The other 20 have a name of 160 bytes or more and fail the same way before and after (a NoMethodError, or a refusal).
- Four programs that do not build or raise on master are right with this change: a keyword or a second parameter spelled `k__bpin` beside an assigned `k` (a C error), a `for` variable, a `rescue =>` variable or a named capture spelled so inside such a block (a C error), and `obj.public_send(f.parameters[0][1])` (NoMethodError for `k__bpin`).
- Generated C: 8 of the 5,797 programs in `test/*.rb` change, each in its symbol table and the Symbol ids the table gives out (the slot's name gives way to the written one; where the written name is already a Symbol the table gets shorter and later ids move down); all 8 pass in a plain run and at `SPINEL_GC_STRESS=2` before and after. The 64 programs in `benchmark/`, the 156 package tests and optcarrot are byte-identical.

Not in this change, each the same before and after:

- `--warn-widen` names the slot in its message (``parameter `k__bpin__bp8` of `m` widened``). It is a compiler diagnostic, not a program's output.
- `Method#inspect` shows the shadow rename's own suffix for a `define_method` parameter that is not assigned (`m(k__bp10)` under an outer local `k`). That is the other rename.
- A parameter name of 160 bytes or more: the pass that renames an assigned parameter keeps its own 160-byte copy, and the parameter is nil in the body. The program raises NoMethodError where the body calls a method nil does not have (`k = k + 1`), prints a wrong line where nil answers it (`k = k.to_s; k + j.to_s` prints `"2"` for `"12"`, in a lambda and in a proc), and does not build where two such names share their first 159 bytes (`redefinition of 'lv_...'`). `parameters` then prints a name that is neither the slot's nor the one written.
- `parameters` of a block that reaches a method as `&b` prints `:""` for the kind, and for a second name; `Method#to_proc.parameters` and `parameters` of a `define_method` method print `[]`; `local_variables` and `binding.local_variables` are not built.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on ab9b925aa)
- [ ] Depends on: # (nothing)
