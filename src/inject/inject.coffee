#### CONTENT SCRIPT
$(document).ready ->
  class WatchDOMFlags
    constructor: (domflags) ->
      @domflagsPanel = $('#domflags-panel')
      @domflags = domflags
      @flaggedElements = []
      @constructFlagEls()
      @setupDomObserver()


    constructFlagEls: ->
      if @domflags.length > 0
        for own key of @domflags
          if $.isNumeric(key)
            elString = @elToString(@domflags[key])
            @flaggedElements.push(elString)

        @backgroundListener()


    backgroundListener: ->
      ## Recreate contextMenu when devtools is open and page is reloaded
      @pageReloaded()

      unless @domflagsPanel.is(":visible") ## prevent duplicate listeners
        ## Receive request for flags. Send flags to background.js
        chrome.runtime.onMessage.addListener (message, sender, sendResponse) =>
          if message is "Remove panel"
            @domflagsPanel.remove()

          else if message is "Give me domflags"
            sendResponse flags: @flaggedElements
            @createDomflagsPanel()

          else if message is "Tab change"
            sendResponse flags: @flaggedElements


    pageReloaded: ->
      chrome.runtime.sendMessage name: "pageReloaded"

    createDomflagsPanel: ->
      unless @domflagsPanel.is(":visible") ## prevent duplicates
        @appendDomflagsPanel()

      elements = ""
      for own key, value of @flaggedElements
        if $.isNumeric(key)
          el = "<domflags-li class='domflags-li' data-key='#{key}'>#{value}</domflags-li>"
          elements = "#{elements} #{el}"

      @domflagsPanel.find('.domflags-ol').append(elements)


    appendDomflagsPanel: ->
      html =  """
              <domflags-panel id="domflags-panel" class="bottom left opened">
                <domflags-header class="domflags-header">DOMFLAGS</domflags-header>
                <domflags-button class="domflags-button right"></domflags-button>
                <domflags-ol class="domflags-ol"></domflags-ol>
              </domflags-panel>
              """
      $(document.body).append html
      @domflagsPanel = $('#domflags-panel')
      @setupDomPanelListeners()


    setupDomPanelListeners: ->
      @domflagsPanel.get(0).addEventListener 'click', (event) =>
        # console.log event, event.target.className
        if event.target.className is 'domflags-li'
          key = $(event.target).attr('data-key')
          chrome.runtime.sendMessage
            name: "panelClick"
            key: key

        else if event.target.className is 'domflags-header'
          if @domflagsPanel.hasClass('opened')
            listHeight = @domflagsPanel.find('.domflags-ol').outerHeight() + 1;
            @domflagsPanel.removeClass('opened').addClass('closed')
            @domflagsPanel.css('transform', "translateY(#{listHeight}px)")

          else if @domflagsPanel.hasClass('closed')
            @domflagsPanel.removeClass('closed').addClass('opened')
            @domflagsPanel.css('transform', "translateY(0px)")

        else if event.target.classList[0] is 'domflags-button'
          targetPos = event.target.classList[1]

          if      targetPos is "left"  then oldPos = "right"
          else if targetPos is "right" then oldPos = "left"

          @domflagsPanel.removeClass(oldPos).addClass(targetPos)
          $(event.target).removeClass(targetPos).addClass(oldPos)


    elToString: (node) ->
      domArray = [node.tagName]
      for own key, value of node.attributes
        if ($.isNumeric(key)) and (value.name isnt "domflag")
          domArray.push("#{value.name}='#{value.value}'")
      elString = domArray.join(' ')
      return elString

    refreshDomPanel: ->
      $('.domflags-li').remove()
      @flaggedElements = []
      @domflags = $('[domflag]')
      @constructFlagEls()


    # // DOM OBSERVER
    # /////////////////////////////////
    setupDomObserver: ->
      observer = new MutationObserver((mutations) =>
        mutations.forEach (mutation) =>
          if mutation.type == "childList"

            removedNodes = mutation.removedNodes
            addedNodes   = mutation.addedNodes

            nodeChange = switch
              when removedNodes.length >= 1 then removedNodes
              when addedNodes.length   >= 1 then addedNodes
              else undefined

            if nodeChange
              for own key, value of nodeChange
                node = nodeChange[key]
                for own key, value of node.attributes
                  if value.name is "domflag"
                    # console.log "DOMFlag Added/Removed", node, mutation
                    @refreshDomPanel()

          else if mutation.type is "attributes"
            # console.log mutation.type, mutation
            if (mutation.oldValue == "") or (mutation.oldValue == null)
              # console.log "DOMFlag Attr added/removes", @elToString(mutation.target)
              @refreshDomPanel()
      )

      config =
        attributeFilter: ['domflag']
        attributeOldValue: true
        attributes: true
        childList: true
        subtree: true

      observer.observe document.body, config

  ## Instantiate WatchDOMFlags
  $domflags = $('[domflag]')
  new WatchDOMFlags($domflags)
