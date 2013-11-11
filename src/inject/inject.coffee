#### CONTENT SCRIPT
# panelMain = document.register("panel-main")
# panelHeader = document.register("panel-header")
# panelOl = document.register("panel-ol")
# panelLi = document.register("panel-li")

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
        $('#domflags').remove()

      else if message is "Give me domflags"
        sendResponse flags: flagElements

        unless $('#domflags').is(":visible") ## prevent duplicates
          elements = ""
          for own key, value of flagElements
            if $.isNumeric(key)
              el = "<panel-li data-key='#{key}'>#{value}</panel-li>"
              elements = "#{elements} #{el}"

          html =  """
                  <panel-main id="domflags" class="opened">
                  <panel-header id="header">DOMFLAGS</panel-header>
                    <panel-ol>
                      #{elements}
                    </panel-ol>
                  </panel-main>
                  """

          $('body').append html
          $domPanel = $('#domflags')
          $domPanel.on 'click', 'panel-li', (event) ->
            key = $(this).attr('data-key')
            chrome.runtime.sendMessage
              name: "panelClick"
              key: key

          $domPanel.on 'click', 'panel-header', (event) ->
            if $domPanel.hasClass('opened')
              listHeight = $domPanel.find('panel-ol').outerHeight() + 1;
              $domPanel.removeClass('opened').addClass('closed')
              $domPanel.css('transform', "translateY(#{listHeight}px)")

            else if $domPanel.hasClass('closed')
              $domPanel.removeClass('closed').addClass('opened')
              $domPanel.css('transform', "translateY(0px)")

    ## Recreate contextMenu when devtools is open and page is reloaded
    chrome.runtime.sendMessage name: "pageReloaded"
