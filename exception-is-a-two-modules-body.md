<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
module Net;  class Error < StandardError; end; end
module Disk; class Error < StandardError; end; end
begin
  raise Net::Error, "down"
rescue => e
  p e.is_a?(Net::Error)   # false; CRuby prints true
end
```

`kind_of?` and `instance_of?` did the same, and so did the bare `Error` inside `module Net`, with a second class of the name or without one. An exception answers by its class's Ruby name (`"Net::Error"`), and the arm compared the text of the argument's path: for a leaf two modules share, `qualify_colliding_classes` has renamed it, so the path read `"Net::Net__Error"`, and a bare name read `"Error"`. No exception carries either.

The exception arm now asks the class table for the name, as the `when` arm does (`exc_when_cls_name`) and as an object receiver's arm already did, where the leaf is a class of the program's and the path is bare or starts at a class or module of the program's. A builtin exception's name and a path under one of CRuby's namespaces (`Errno::ENOENT`) compare as before.

Not here: an exception of a class made by `Class.new(Net::Error)` still answers false for `is_a?(Net::Error)`.

Test: `test/exc_is_a_same_leaf.rb`, 3 of its 4 lines different on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
