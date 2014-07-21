#### CONTENT SCRIPT

## toggleDomflag for keyboard shortcuts
## create new tabs to test
@toggleDomflag = (el) ->
  if el.hasAttribute('domflag')
    el.removeAttribute('domflag', '')
  else
    el.setAttribute('domflag', '')

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

  _cacheDomflagsPanel: ->
    if @shadowRoot?
      @domflagsPanel = @shadowRoot.getElementById('domflags-panel')
    else @appendDomflagsPanel()

  _cacheDomflags: ->
    @domflags = document.querySelectorAll('[domflag]')

  _calibrateIndexes: ->
    panelItem.setAttribute 'data-key', i for panelItem, i in @_getPanelItems()

  _getPanelItems: ->
    @domflagsPanel.getElementsByClassName('domflags-li')

  backgroundListener: ->
    chrome.runtime.onMessage.addListener (message, sender, sendResponse) =>
      if message is "remove"
        @domflagsPanel.parentNode.removeChild(@domflagsPanel)
        @_cacheDomflagsPanel()

      if message is "create" and not @domflagsPanel?
        @addNodesToPanel(@domflags) if @domflags.length > 0

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
      rootEl = document.createElement 'domflags'
      rootEl.setAttribute "id", "domflags-root"
      document.body.appendChild(rootEl, document.body.childNodes[0])
      @shadowRoot = document.getElementById('domflags-root').createShadowRoot()
      @shadowRoot.innerHTML = styleTag

    @shadowRoot.innerHTML += panelHTML
    @_cacheDomflagsPanel()
    @panelList = @domflagsPanel.getElementsByClassName('domflags-ol')[0]
    @createPanelListeners()


  createPanelListeners: ->
    @domflagsPanel.addEventListener 'click', (event) =>
      switch event.target.classList[0]
        when 'domflags-li'     then triggerPanel(event)
        when 'domflags-header' then triggerHeader()
        when 'domflags-button' then triggerPanelPos(event)

    triggerPanel = (event) ->
      key = event.target.getAttribute('data-key')
      chrome.runtime.sendMessage
        name: "panelClick"
        key: key

    triggerHeader = =>
      closePanel =
        remove: "opened"
        add: "closed"
        height: @panelList.offsetHeight + 1

      openPanel =
        remove: "closed"
        add: "opened"
        height: 0

      panelSwitch = switch
        when @domflagsPanel.classList.contains('opened') then closePanel
        when @domflagsPanel.classList.contains('closed') then openPanel

      listHeight = panelSwitch.height
      @domflagsPanel.classList.remove panelSwitch.remove
      @domflagsPanel.classList.add panelSwitch.add
      $(@domflagsPanel).css('transform', "translateY(#{listHeight}px)")

    triggerPanelPos = (event) =>
      targetPos = event.target.classList[1]

      switch targetPos
        when "left"  then oldPos = "right"
        when "right" then oldPos = "left"

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

    addNodes = (el) =>
      @panelList.innerHTML += el

    positionNodes = (el, index) ->
      if index > 0 then $(panelItems[index - 1]).after(el)
      else $(panelItems[0]).before(el)

    for node in newNodes
      return if !node.hasAttribute('domflag')

      elString = @elToString(node)
      @_cacheDomflags()
      index = [].indexOf.call(@domflags, node)
      @flagStrings.splice(index, 0, elString)
      el = "<domflags-li class='domflags-li' data-key='#{index}'>#{elString}</domflags-li>"

      switch
        when panelItems.length > 0 then positionNodes(el, index)
        else addNodes(el)

    @_calibrateIndexes()

  removeNodesFromPanel: (deletedNodes) ->
    @_cacheDomflagsPanel()
    return if not @domflagsPanel?

    panelItems = @_getPanelItems()
    for node in deletedNodes.slice(0).reverse()
      index = [].indexOf.call(@domflags, node)
      @flagStrings.splice(index, 1)

      panelItem = panelItems[index]

      continue if not panelItem?
      panelItem.parentNode.removeChild(panelItem)

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

$(document).ready ->
  new WatchDOMFlags document.querySelectorAll('[domflag]')
