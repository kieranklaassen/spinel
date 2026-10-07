# A method's parameter default is evaluated by the caller, before the method's
# frame opens. A program whose default matches keeps the registers as they are:
# here the body reads the match its own default made.
def digit(s, at = (s =~ /k(\d)/))
  [$1, at]
end

def keyed(s, d: s[/k(\d)/, 1])
  [$1, d]
end

"ab" =~ /(b)/
p digit("zk7")
"ab" =~ /(b)/
p keyed("zk8")
