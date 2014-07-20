#### CONTENT SCRIPT

## toggleDomflag for keyboard shortcuts
## create new tabs to test
@toggleDomflag = (el) ->
  if el.hasAttribute('domflag')
    el.removeAttribute('domflag', '')
  else
    el.setAttribute('domflag', '')

$(document).ready ->
  class WatchDOMFlags
    constructor: (domflags) ->
      @domflags      = domflags
      @domflagsPanel = undefined
      @panelList     = undefined
      @shadowRoot    = undefined
      @modifiedNodes = undefined
      @flagStrings   = []
      @configVars    =
        attributes: true
        attributeFilter: ['domflag']
        attributeOldValue: false
        childList: true
        subtree: true

      @backgroundListener()
      @setupDomObserver()

    _cacheDomflags: ->
      @domflags = document.querySelectorAll('[domflag]')

    _getPanelItems: ->
      @domflagsPanel.getElementsByClassName('domflags-li')

    _calibrateIndexes: ->
      panelItem.setAttribute 'data-key', i for panelItem, i in @_getPanelItems()

    backgroundListener: ->
      ## Receive requests from background script
      chrome.runtime.onMessage.addListener (message, sender, sendResponse) =>
        if message is "remove"
          @domflagsPanel.remove()
          @domflagsPanel = @shadowRoot.getElementById('domflags-panel')

        if message is "create" and @domflags.length > 0
          unless @domflagsPanel ## prevent duplicates
            @addNodesToPanel(@domflags)


    appendDomflagsPanel: ->
      cssPath = chrome.extension.getURL("src/inject/inject.css")
      styleTag = """<style type="text/css" media="screen">@import url(#{cssPath});</style>"""
      panelHTML =  """
              <domflags-panel id="domflags-panel" class="bottom left opened">
                <domflags-header class="domflags-header">DOMFLAGS</domflags-header>
                <domflags-button class="domflags-button right"></domflags-button>
                <domflags-ol class="domflags-ol"></domflags-ol>
              </domflags-panel>
              """
      unless document.getElementById('domflags-root')?
        $(document.body).append '<domflags id="domflags-root"></domflags>' # native JS bug
        @shadowRoot = document.querySelector('#domflags-root').createShadowRoot()
        @shadowRoot.innerHTML = styleTag

      @shadowRoot.innerHTML += panelHTML
      @domflagsPanel = @shadowRoot.getElementById('domflags-panel')
      @panelList = @domflagsPanel.querySelector('.domflags-ol')
      @createPanelListeners()


    createPanelListeners: ->
      @domflagsPanel.addEventListener 'click', (event) =>
        if event.target.className is 'domflags-li'
          key = $(event.target).attr('data-key')
          chrome.runtime.sendMessage
            name: "panelClick"
            key: key

        else if event.target.className is 'domflags-header'
          if @domflagsPanel.classList.contains('opened')
            listHeight = $(@panelList).outerHeight() + 1;
            @domflagsPanel.classList.remove('opened')
            @domflagsPanel.classList.add('closed')

          else if @domflagsPanel.classList.contains('closed')
            listHeight = 0
            @domflagsPanel.classList.remove('closed')
            @domflagsPanel.classList.add('opened')

          $(@domflagsPanel).css('transform', "translateY(#{listHeight}px)")

        else if event.target.classList[0] is 'domflags-button'
          targetPos = event.target.classList[1]

          if      targetPos is "left"  then oldPos = "right"
          else if targetPos is "right" then oldPos = "left"

          @domflagsPanel.classList.remove(oldPos)
          @domflagsPanel.classList.add(targetPos)
          event.target.classList.remove(targetPos)
          event.target.classList.add(oldPos)

    elToString: (node) ->
      tagName   = node.tagName.toLowerCase()
      idName    = if node.id then "#" + node.id else ""
      className = if node.className then "." + node.className else ""
      return tagName + idName + className


    addNodesToPanel: (newNodes) ->
      unless @domflagsPanel?
        @appendDomflagsPanel()

      panelItems = @_getPanelItems()
      for node in newNodes
        elString = @elToString(node)

        if node.hasAttribute('domflag')
          @_cacheDomflags()
          index = $(@domflags).index(node)
          @flagStrings.splice(index, 0, elString)
          el = "<domflags-li class='domflags-li' data-key='#{index}'>#{elString}</domflags-li>"

          addItems = =>
            @panelList.innerHTML += el

          positionItems = ->
            if index >= 1
              $(panelItems[index - 1]).after(el)
            else
              $(panelItems[0]).before(el)

          switch
            when panelItems.length > 0 then positionItems()
            else addItems()

      @_calibrateIndexes()

    removeNodesFromPanel: (deletedNodes) ->
      panelItems = @_getPanelItems()
      for node in deletedNodes.slice(0).reverse()
        index = $(@domflags).index(node)
        @flagStrings.splice(index, 1)
        $(panelItems[index]).remove()
      @_cacheDomflags()
      @_calibrateIndexes()

    # // DOM OBSERVER
    # /////////////////////////////////
    setupDomObserver: ->
      observer = new MutationObserver((mutations) =>
        @modifiedNodes = new: [], deleted: []
        for mutation in mutations
          switch mutation.type
            when "childList"  then @parseChildList(mutation)
            when "attributes" then @parseAttrs(mutation)
          continue

        @removeNodesFromPanel(@modifiedNodes.deleted) if @modifiedNodes.deleted.length > 0
        @addNodesToPanel(@modifiedNodes.new) if @modifiedNodes.new.length > 0
      )
      observer.observe document.body, @configVars

    parseChildList: (mutation) ->
      addedNodes =
        mutation: mutation.addedNodes
        panelArray: @modifiedNodes.new
      removedNodes =
        mutation: mutation.removedNodes
        panelArray: @modifiedNodes.deleted

      nodeChange = switch
        when addedNodes.mutation.length   > 0 then addedNodes
        when removedNodes.mutation.length > 0 then removedNodes

      push = (node) ->
        nodeChange.panelArray.push(node) if node not in nodeChange.panelArray

      return if not nodeChange?

      for node in nodeChange.mutation
        continue if node.nodeName is "#text"

        if (node.hasAttribute('domflag'))
          push(node)

        for node in node.querySelectorAll('[domflag]')
          push(node)

    parseAttrs: (mutation) ->
      if mutation.target.hasAttribute('domflag') then @modifiedNodes.new.push(mutation.target)
      else @modifiedNodes.deleted.push(mutation.target)

  ## Instantiate WatchDOMFlags
  domflags = document.querySelectorAll('[domflag]')
  new WatchDOMFlags(domflags)
