# console.log "background.js"

# background.js
chrome.runtime.onMessage.addListener (message, sender, sendResponse) ->

  ## Create the Menus Items for the Context Menu
  createMenuItems = (flags) ->
    for own key, value of flags
      # console.log value
      chrome.contextMenus.create
        title: value
        id: "#{key}"
        contexts: ['all']

  createMenuItems(message.flags)


  ## Connect when the devtools panel is open
  chrome.runtime.onConnect.addListener (port) ->

    ## Send the key of the clicked menu item to devtools
    onClickHandler = (info, tab) ->
      port.postMessage key: info.menuItemId

    chrome.contextMenus.onClicked.addListener onClickHandler


# openCount = 0
# chrome.runtime.onConnect.addListener (port) ->
  # if port.name is "devtools"
    # alert "DevTools window opening."  if openCount is 0
    # openCount++
    # port.onDisconnect.addListener (port) ->
      # openCount--
      # alert "Last DevTools window closing."  if openCount is 0



chrome.tabs.onActivated.addListener (activeInfo) ->
  console.log activeInfo.tabId

  ## Send message to content script to get DOM flags. Receive flags.
  chrome.tabs.sendMessage activeInfo.tabId, "hello world" , (response) ->
    if response
      console.log response.flags
      ## Update the context menus with correct DOM NODES
