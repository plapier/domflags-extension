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
