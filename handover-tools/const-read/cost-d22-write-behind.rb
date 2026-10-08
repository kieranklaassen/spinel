module Lib; class X; def foo = "foo"; end; end
module Lib2; class X; def bar = "bar"; end; end
class X; def hi = "hi"; end
module A22; class X; def hi = "deep"; end; end; module B22; end
module A21; include A22, B22; end; module B21; include A22, B22; end
module A20; include A21, B21; end; module B20; include A21, B21; end
module A19; include A20, B20; end; module B19; include A20, B20; end
module A18; include A19, B19; end; module B18; include A19, B19; end
module A17; include A18, B18; end; module B17; include A18, B18; end
module A16; include A17, B17; end; module B16; include A17, B17; end
module A15; include A16, B16; end; module B15; include A16, B16; end
module A14; include A15, B15; end; module B14; include A15, B15; end
module A13; include A14, B14; end; module B13; include A14, B14; end
module A12; include A13, B13; end; module B12; include A13, B13; end
module A11; include A12, B12; end; module B11; include A12, B12; end
module A10; include A11, B11; end; module B10; include A11, B11; end
module A9; include A10, B10; end; module B9; include A10, B10; end
module A8; include A9, B9; end; module B8; include A9, B9; end
module A7; include A8, B8; end; module B7; include A8, B8; end
module A6; include A7, B7; end; module B6; include A7, B7; end
module A5; include A6, B6; end; module B5; include A6, B6; end
module A4; include A5, B5; end; module B4; include A5, B5; end
module A3; include A4, B4; end; module B3; include A4, B4; end
module A2; include A3, B3; end; module B2; include A3, B3; end
module A1; include A2, B2; end; module B1; include A2, B2; end
class User; include A1; def go = X.new.hi; end
p User.new.go
p Lib::X.new.foo, Lib2::X.new.bar
