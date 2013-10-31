# console.log "background.js"

updateContextMenus = (flags) ->
  chrome.contextMenus.removeAll()
  if flags.length > 0
    for own key, value of flags
      chrome.contextMenus.create
        title: value
        id: "#{key}"
        contexts: ['all']

chrome.runtime.onMessage.addListener (message, sender, sendResponse) ->
  updateContextMenus(message.flags)

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
  ## Send message to content script to get DOM flags. Receive flags.
  chrome.tabs.sendMessage activeInfo.tabId, "give me domflags" , (response) ->
    if response
      updateContextMenus(response.flags)
