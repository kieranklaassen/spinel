# Flag-only: without the flag a constant's or a class variable's String is a copy at each read.
# A local a pattern binds to a whole subject that is a constant, a constant
# in a module or a class variable is that String, so a change through the
# local is the subject's.
LINE = +"zz"
case LINE
in String => s
  s << "!"
end
p LINE, s, s.equal?(LINE)
module Cfg
  NAME = +"cfg"
end
case Cfg::NAME
in t
  t << "?"
end
p Cfg::NAME, t
class Log
  @@buf = +"log"
  def self.mark
    case @@buf
    in String => b
      b << "#"
    end
    @@buf << "+"
    p @@buf, b
  end
end
Log.mark
if LINE in String => u
  u << "2"
end
LINE << "3"
p LINE, u
# a local that already holds another String's handle
class Page
  attr_reader :text
  def initialize
    @text = +"k"
  end
end
page = Page.new
v = page.text << "a"
case Cfg::NAME
in String => v
  v << "4"
end
p Cfg::NAME, v, page.text
# an earlier arm that runs no code leaves the slot as the case read it: a
# class pattern that fails, a guard that only compares
class Tally
  @@c = +"zz"
  @@d = +"yy"
  def self.go(n)
    case @@c
    in Integer => i
      p :no
    in String => s if n > 3
      p :no
    in String => s
      s << "!"
    end
    p @@c, s
  end
  # an earlier arm's guard assigns the class variable, in its text or in a
  # method it calls: the binding is the String the case read
  def self.swap = (@@d = +"new"; false)
  def self.guarded
    case @@c
    in String => t if (@@c = +"other"; false)
      p :no
    in String => s
      s << "?"
    end
    p @@c, s
    case @@d
    in String => t if swap
      p :no
    in String => s
      s << "?"
    end
    p @@d, s
  end
end
Tally.go(1)
Tally.guarded
