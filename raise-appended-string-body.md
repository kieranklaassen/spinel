<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
begin
  raise h["k"]
rescue RuntimeError => e
  puts "rescued " + e.message
end
```

ends with an uncaught TypeError, exception class/object expected (`spinel diff`: exception-diff). CRuby prints `rescued ab`.

A boxed String the program appends to is kept as a shared handle, and its tag is not `SP_TAG_STR`. `sp_raise_poly`, which takes a raise's one argument when its kind is known only at run time, tested that tag alone, so the handle went the way of a value that is neither a String, an exception nor an exception class. Now it raises RuntimeError with a copy of the handle's text. `raise` with a class and such a message, and `Exception.new` with one, were right already.

Cost: none where nothing is raised; `sp_raise_poly` is cold, and a raise of an exception object or a class passes one more test. The change is in lib/spinel_rt.h, so no generated C changes.

Not changed: the message is the text at the raise. An append after it does not show in `e.message`, where CRuby's message is the String itself; `Exception.new(h["k"])` reads the same way on master. An empty appended String raises with the class name as its message where CRuby's message is empty, as a plain boxed `""` does on master.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
