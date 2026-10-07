#!/usr/bin/env ruby
# usage: select5.rb g5.conly.tsv -> prints the selected program names (stdin: none)
KEYS = %w[get set def list rm]
sel = []
File.foreach(ARGV[0]) do |l|
  name = l.split("\t").first
  parts = name.split("_")
  fam = parts[1]
  rest = parts[2..]
  ki = rest.index { |x| KEYS.include?(x) }
  key = ki ? rest[ki] : nil
  label = ki ? rest[0...ki].join("_") : rest.join("_")
  tail = ki ? rest[(ki + 1)..] : []
  keep = case fam
         when "A"
           use = tail.join("_")
           if use == "p" then %w[private protected undef raises].include?(label)
           elsif use == "var" then %w[get list].include?(key)
           else true end
         when "A2"
           use = tail.join("_")
           if %w[str same none].include?(label)
             %w[get set list].include?(key) || %w[send safe meth mapb resp].include?(use)
           else
             %w[get set].include?(key) && %w[send safe meth resp eq].include?(use)
           end
         when "B", "F", "G", "I" then true
         when "C"
           rk = tail.join("_")
           case label
           when "str" then %w[get set list].include?(key) || %w[ivar self bare boxed param2 nilable].include?(rk)
           when "same" then key == "get" || %w[ivar self bare boxed].include?(rk)
           when "none" then key == "get" || %w[self bare boxed].include?(rk)
           when "int", "struct", "include" then %w[get set list].include?(key)
           else key == "get" end
         when "C2" then %w[get set list].include?(key)
         when "D"
           case label
           when "same", "none" then true
           when "samecase" then %w[get def list].include?(key)
           when "super" then (tail[0] == "int" && tail[1].to_i < 2) || (%w[def list].include?(key) && tail[0].to_i < 2)
           end
         when "E" then %w[get set list].include?(key)
         when "Er" then %w[get set].include?(key)
         when "H" then tail.last == "p" || key == "get"
         else true
         end
  sel << name if keep
end
puts sel
