# const_set with a computed name binds LIM anew in CRuby. Here the call is
# not performed and raises NoMethodError, which the program rescues.
LIM = 1..5
begin
  Object.const_set("LI" + "M", String)
rescue NoMethodError
end
p(LIM === 3)
