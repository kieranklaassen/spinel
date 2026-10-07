# A `when` value that cannot match its subject's kind is still evaluated:
# a call written there runs, as it does in CRuby. `case 5` with `when name`
# for a method answering a String was compiled to `if (0)`, and the call
# was dropped.

$n = 0
$log = []
def str; $n += 1; "s"; end
def sym; $n += 1; :a; end
def int; $n += 1; 5; end
def flt; $n += 1; 2.5; end
def yes; $n += 1; true; end
def note(tag, v); $log << tag; v; end

class Src
  def name; $n += 1; "t"; end
end
SRC = Src.new

def count
  $n = 0
  r = yield
  puts "#{r} n=#{$n}"
end

# each subject kind beside a value of another kind
count { case 5 when str then "m" else "e" end }
count { case 5 when sym then "m" else "e" end }
count { case 5 when yes then "m" else "e" end }
count { case 2.5 when str then "m" else "e" end }
count { case "s" when int then "m" else "e" end }
count { case "s" when sym then "m" else "e" end }
count { case :a when str then "m" else "e" end }
count { case :a when flt then "m" else "e" end }
count { case true when int then "m" else "e" end }
count { case true when str then "m" else "e" end }

# a local subject, a method on an object, an assignment as the value
x = 5
count { case x when SRC.name then "m" else "e" end }
count { case x when (w = ($n += 1; "s")) then "m" else "e" end }

# every value of a list runs until one matches, in order
count { case 5 when str, sym, 5 then "m" else "e" end }
count { case 5 when str, 5, sym then "m" else "e" end }
r = case 5
    when note(:a, "s") then 1
    when note(:b, :k), note(:c, 5) then 2
    when note(:d, "u") then 3
    end
p r, $log

# the statement form, and inside a method
$n = 0
case x
when str then puts "m"
else puts "e"
end
puts "n=#{$n}"

def pick(q)
  case q
  when sym then :m
  else :e
  end
end
$n = 0
p pick("s"), $n

# a value of the subject's own kind matches as before
count { case 5 when int then "m" else "e" end }
count { case "s" when str then "m" else "e" end }
count { case :a when sym then "m" else "e" end }
