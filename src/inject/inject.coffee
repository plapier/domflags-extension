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
      if message is "Remove panel"
        $('#domflags-panel').remove()

      else if message is "Give me domflags"
        sendResponse flags: flagElements

        unless $('#domflags-panel').is(":visible") ## prevent duplicates
          elements = ""
          for own key, value of flagElements
            if $.isNumeric(key)
              el = "<li data-key='#{key}'>#{value}</li>"
              elements = "#{elements} #{el}"

          html =  """
                  <section id="domflags-panel" class="opened">
                  <header>DOMFLAGS</header>
                    <ol>
                      #{elements}
                    </ol>
                  </section>
                  """

          $('body').append html
          $domPanel = $('#domflags-panel')
          $domPanel.on 'click', 'li', (event) ->
            key = $(this).attr('data-key')
            chrome.runtime.sendMessage
              name: "panelClick"
              key: key

          $domPanel.on 'click', 'header', (event) ->
            if $domPanel.hasClass('opened')
              listHeight = $domPanel.find('ol').outerHeight() + 1;
              $domPanel.removeClass('opened').addClass('closed')
              $domPanel.css('transform', "translateY(#{listHeight}px)")

            else if $domPanel.hasClass('closed')
              $domPanel.removeClass('closed').addClass('opened')
              $domPanel.css('transform', "translateY(0px)")

    ## Recreate contextMenu when devtools is open and page is reloaded
    chrome.runtime.sendMessage
      name: "pageReloaded"
