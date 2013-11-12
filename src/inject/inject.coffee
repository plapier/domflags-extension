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
        $('#domflags').remove()

      else if message is "Give me domflags"
        sendResponse flags: flagElements

        unless $('#domflags').is(":visible") ## prevent duplicates
          elements = ""
          for own key, value of flagElements
            if $.isNumeric(key)
              el = "<domflag-li data-key='#{key}'>#{value}</domflag-li>"
              elements = "#{elements} #{el}"

          html =  """
                  <domflag-panel id="domflags" class="opened">
                    <domflag-header id="header">DOMFLAGS</domflag-header>
                    <domflag-ol>
                      #{elements}
                    </domflag-ol>
                  </domflag-panel>
                  """

          $('body').append html
          $domPanel = $('#domflags')
          $domPanel.on 'click', 'domflag-li', (event) ->
            key = $(this).attr('data-key')
            chrome.runtime.sendMessage
              name: "panelClick"
              key: key

          $domPanel.on 'click', 'domflag-header', (event) ->
            if $domPanel.hasClass('opened')
              listHeight = $domPanel.find('domflag-ol').outerHeight() + 1;
              $domPanel.removeClass('opened').addClass('closed')
              $domPanel.css('transform', "translateY(#{listHeight}px)")

            else if $domPanel.hasClass('closed')
              $domPanel.removeClass('closed').addClass('opened')
              $domPanel.css('transform', "translateY(0px)")

    ## Recreate contextMenu when devtools is open and page is reloaded
    chrome.runtime.sendMessage name: "pageReloaded"
