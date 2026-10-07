# The same for a constant's Hash whose values are typed String.
H = { "a" => +"q", "b" => +"r" }
2.times { H["a"] << "Z" }
p H["a"]
