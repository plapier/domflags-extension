#### CONTENT SCRIPT

$(document).ready ->
  init()

init = ->
  $domflags = $('[domflag]')
  flagElements = []
  if $domflags.length > 0
    for own key of $domflags
      if $.isNumeric(key)
        domTag = $domflags[key].tagName
        domArray = [domTag]
        Array::slice.call($domflags[key].attributes).forEach (item) ->
          domArray.push("#{item.name}='#{item.value}'") if item.name != "domflag"

        domString = domArray.join(' ')
        flagElements.push(domString)

    ## Receive request for flags. Send flags to background.js
    chrome.runtime.onMessage.addListener (message, sender, sendResponse) ->
      if message is "Give me domflags"
        sendResponse flags: flagElements

    elements = ""
    for own key, value of flagElements
      if $.isNumeric(key)
        el = "<li data-key='#{key}'>#{value}</li>"
        elements = "#{elements} #{el}"

    html =  """
            <section id="domflags-panel">
            <header>DOMFLAGS</header>
              <ol>
                #{elements}
              </ol>
            </section>
            """

    $('body').append html
    $('#domflags-panel').on 'click', 'li', (event) ->
      key = $(this).attr('data-key')
      chrome.runtime.sendMessage
        name: "panelClick"
        key: key
