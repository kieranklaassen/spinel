<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

The text of a string literal is data, and nothing in the tree checks that the compiler reads it as data. Several passes read text: the write barrier, the root elision and the root frame read the generated C, the call emitters search an arm's C for a name, and the parser searches the Ruby source for what a program mentions. A literal that spells what one of them looks for is read as code. In a class with an `@leaf` that holds a reference, `def describe = "a store is spelled self->iv_leaf = leaf; in C"` answers `a store is spelled SP_WBO(self)->iv_leaf = le`, and `puts "issue #12"; p [1, 2, 3].partition { |v| v > 1 }` raises NoMethodError for `partition`, which the `#` hid from the scan that splices the builtins a program mentions.

`tools/literal_probe.rb` plants a string literal in void position at the head of every method, block and lambda body and of the top level (or, with `--plant operand`, around every receiver and argument that is a variable or a call) and compiles the program twice: with a needle in each literal, and with a control of the same bytes turned to `x`. The two C files have to be equal outside the planted literals, and each literal has to read back as it was written. The needle is the lines of the C function the literal lands in (`--needle own`), or every string the sources hand to `strstr`, `strncmp` or `memcmp` (`--needle searched`, read from `src/` when the probe starts). A program that differs is reduced by delta debugging to the shortest literal that still differs; triggers alike but for a program's own names are one family, and twenty programs of each family are built and run both ways.

On 5204e5af, over the 5,404 programs of `test/` it can compare, 1,153 differ with their own C in the literals, in 9 families. In 1,071 a literal that spells `->iv_NAME=` comes out of `gc_wb_insert_seg` as `SP_WBO(...)->iv_NAME=`, in an array declared with the length it had before. In 124 the word `break` splices `builtins/enumerator.rb` into a program that breaks out of nothing. In 4 a block whose text spells `sp_raise_nomethod(` loses the String arm of a poly `each_line`, and two of them raise NoMethodError where the control answers. With the searched strings 5,401 differ, in 20 families: `define_finalizer` in any string splices `builtins/object_space.rb` into 5,395 programs and makes `test/poly_index_not_proc.rb` refused; `SP_GC_ROOT`, `setjmp` and `sp_gc_nroots` each keep a dead `SP_GC_SAVE` in 1,943; a `#` hides the builtins named after it on its line in 79, and of the 20 run two raise NoMethodError. Around operands, 412 of 5,073 programs differ: a `)` in a literal in the receiver of an attribute write moves where `wb_lvalue_start` takes the lvalue to start in 60, and the C of 19 of the 20 run does not build; in 4 a literal of about 400 bytes is cut at a fixed buffer, and the C does not build. The commit message has every family.

Compiled twice, the control reports nothing in the two passes over bodies, and around operands only those 4 programs, which is what the control shows alone.

A probe to run by hand, like `order_probe`: a CRuby script that needs only Prism, not a gate, and not one of the tools make builds. The three passes take 9, 34 and 18 minutes at `--jobs 4`. It adds one file under `tools/` and a section in `tools/README.md`. Nothing under `src/`, `lib/` or `test/` changes, and no finding is fixed here.

## `make gate` (on this branch merged with current master)

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.73x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.32x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.26x (linear 4.00, limit 4.50)
Tests: 5580 pass, 2 fail, 0 error
```

Run on this branch at 8f783875, which is 5ee16b74 plus this commit. The two failures are `test/socket_ipv6_and_class_methods.rb` and `pkg.tmpdir.tmpdir_expand_usable`, and both fail the same way on master without this commit on the machine this ran on: it has no IPv6 (CRuby raises `EAFNOSUPPORT` on `UDPSocket.new(Socket::AF_INET6)` there too), and the tmpdir test prints `false` for its first line there. The gate stops at the test leg for them, so it prints no `gate:` line. The other legs pass: benchmarks 64 of 64, optcarrot with checksum 59662, ruby/spec with every expected-PASS example still passing. The commit touches nothing the gate builds or runs.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no test is added)
- [ ] Values past 2^31 are marked `# spinel: int64` (no test is added)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change; the compiler is untouched)
- [ ] Depends on: # (nothing)
