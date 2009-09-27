module AboutHelper
  def dialog(id, &block)
    concat %(<div id="#{id}"><div class="dialog">)
    concat '<div class="hd"><div class="c"></div></div>'
    concat '<div class="bd"><div class="c"><div class="s">'
    yield
    concat '</div></div></div>'
    concat '<div class="ft"><div class="c"></div></div>'
    concat "</div></div>"
  end
end
