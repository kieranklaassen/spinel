# A method that appends to its String parameter and has an alias. The
# alias's calls hand over values, so the method takes a copy and the
# append would not reach `buf` (CRuby prints "<p>hi</p>"). Refused at
# compile time until it can be shared (#6179); `def to_html(out) =
# render(out)` in place of the alias is shared.
class Html
  def render(out)
    out << "<p>"
    out << "hi"
    out << "</p>"
  end
  alias to_html render
end
buf = +""
Html.new.render(buf)
p buf
