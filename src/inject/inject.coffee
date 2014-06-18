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
      @domflags = domflags
      @domflagsPanel = undefined
      @panelList = undefined
      @flagStrings = []

      @backgroundListener()
      @setupDomObserver()

    backgroundListener: ->
      ## Receive request for flags. Send flags to background.js
      chrome.runtime.onMessage.addListener (message, sender, sendResponse) =>
        if message is "remove"
          $(@domflagsPanel).remove()

        if message is "create" and @domflags.length > 0
            @addNodesToPanel(@domflags)


    appendDomflagsPanel: ->
      html =  """
              <domflags-panel id="domflags-panel" class="bottom left opened">
                <domflags-header class="domflags-header">DOMFLAGS</domflags-header>
                <domflags-button class="domflags-button right"></domflags-button>
                <domflags-ol class="domflags-ol"></domflags-ol>
              </domflags-panel>
              """
      $(document.body).append html
      @domflagsPanel = document.getElementById('domflags-panel')
      @panelList = $(@domflagsPanel).find('.domflags-ol')
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
            listHeight = @panelList.outerHeight() + 1;
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

    nodeListToArray: (nodeList) ->
      Array::slice.call(nodeList)

    elToString: (node) ->
      domArray = [node.tagName]
      for value, key in node.attributes
        if value.name isnt "domflag"
          domArray.push("#{value.name}='#{value.value}'")
      elString = domArray.join(' ')
      return elString

    cacheDomflags: ->
      @domflags = document.querySelectorAll('[domflag]')

    calibrateIndexes: ->
      tags = @panelList[0].getElementsByTagName('domflags-li')
      tag.setAttribute 'data-key', i for tag, i in tags

    addNodesToPanel: (newNodes) ->
      newNodes = @nodeListToArray(newNodes)
      unless document.getElementById('domflags-panel')?
        @appendDomflagsPanel()

      panelItems = document.getElementsByClassName('domflags-li')
      for node in newNodes
        elString = @elToString(node)

        if node.hasAttribute('domflag')
          @cacheDomflags()
          index = $(@domflags).index(node)
          @flagStrings.splice(index, 0, elString)
          el = "<domflags-li class='domflags-li' data-key='#{index}'>#{elString}</domflags-li>"

          if panelItems.length > 0
            if index >= 1
              $(panelItems[index - 1]).after(el)
            else
              $(panelItems[0]).before(el)
          else
            @panelList.append(el)
      @calibrateIndexes()

    removeNodesFromPanel: (deletedNodes) ->
      panelItems = document.getElementsByClassName('domflags-li')
      for node in deletedNodes.slice(0).reverse()
        index = $(@domflags).index(node)
        @flagStrings.splice(index, 1)
        $(panelItems[index]).remove()
      @cacheDomflags()
      @calibrateIndexes()

    # // DOM OBSERVER
    # /////////////////////////////////
    setupDomObserver: ->
      observer = new MutationObserver((mutations) =>
        newNodes = []
        deletedNodes = []
        mutations.forEach (mutation) =>
          ## A node has been added / deleted
          if mutation.type is "childList"

            addedNodes =
              mutation: mutation.addedNodes
              panelArray: newNodes
            removedNodes =
              mutation: mutation.removedNodes
              panelArray: deletedNodes

            nodeChange = switch
              when addedNodes.mutation.length   > 0 then addedNodes
              when removedNodes.mutation.length > 0 then removedNodes
              else undefined

            if nodeChange
              for own key, value of nodeChange.mutation
                node = nodeChange.mutation[key]
                for own key, value of node.attributes
                  if value.name is "domflag"
                    ## build a list of nodes that are added / removed
                    childrenArray = @nodeListToArray(node.querySelectorAll("[domflag]"))
                    nodeChange.panelArray.push(node)
                    nodeChange.panelArray.push(item) for item in childrenArray
                    # console.log "DOMFlag Added/Removed", node, mutation

          ## Attribute has been added / deleted
          else if mutation.type is "attributes"
            if (mutation.oldValue == "") or (mutation.oldValue == null)
              if mutation.target.hasAttribute('domflag')
                newNodes.push(mutation.target)
              else
                deletedNodes.push(mutation.target)

        @removeNodesFromPanel(deletedNodes) if deletedNodes.length > 0
        @addNodesToPanel(newNodes) if newNodes.length > 0
      )

      config =
        attributeFilter: ['domflag']
        attributeOldValue: false
        attributes: true
        childList: true
        subtree: true

      observer.observe document.body, config

  ## Instantiate WatchDOMFlags
  domflags = document.querySelectorAll('[domflag]')
  new WatchDOMFlags(domflags)
