console.log "background.js"

# background.js
connections = {}
chrome.runtime.onConnect.addListener (port) ->
  extensionListener = (message, sender, sendResponse) ->
    # The original connection event doesn't include the tab ID of the
    # DevTools page, so we need to send it explicitly.
    if message.name is "init"
      connections[message.tabId] = port
      return

  # other message handling

  # Listen to messages sent from the DevTools page
  port.onMessage.addListener extensionListener
  port.onDisconnect.addListener (port) ->
    port.onMessage.removeListener extensionListener
    tabs = Object.keys(connections)
    i = 0
    len = tabs.length

    while i < len
      if connections[tabs[i]] is port
        delete connections[tabs[i]]

        break
      i++



# Receive message from content script and relay to the devTools page for the
# current tab
chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  
  # Messages from content scripts should have sender.tab set
  if sender.tab
    tabId = sender.tab.id
    if tabId of connections
      connections[tabId].postMessage request
    else
      console.log "Tab not found in connection list."
  else
    console.log "sender.tab not defined."
  true


# The onClicked callback function.
onClickHandler = (info, tab) ->
  if info.menuItemId is "radio1" or info.menuItemId is "radio2"
    console.log "radio item " + info.menuItemId + " was clicked (previous checked state was " + info.wasChecked + ")"
  else if info.menuItemId is "checkbox1" or info.menuItemId is "checkbox2"
    console.log JSON.stringify(info)
    console.log "checkbox item " + info.menuItemId + " was clicked, state is now: " + info.checked + " (previous state was " + info.wasChecked + ")"
  else
    console.log "item " + info.menuItemId + " was clicked"
    console.log "info: " + JSON.stringify(info)
    console.log "tab: " + JSON.stringify(tab)

chrome.contextMenus.onClicked.addListener onClickHandler

# Set up context menu tree at install time.
chrome.runtime.onInstalled.addListener ->
  # Create one test item for each context type.
  contexts = ["page", "selection", "link", "editable", "image", "video", "audio"]
  i = 0

  while i < contexts.length
    context = contexts[i]
    title = "Test '" + context + "' menu item"
    id = chrome.contextMenus.create(
      title: title
      contexts: [context]
      id: "context" + context
    )
    console.log "'" + context + "' item:" + id
    i++
  
  # Create a parent item and two children.
  chrome.contextMenus.create
    title: "Test parent item"
    id: "parent"

  chrome.contextMenus.create
    title: "Child 1"
    parentId: "parent"
    id: "child1"

  chrome.contextMenus.create
    title: "Child 2"
    parentId: "parent"
    id: "child2"

  console.log "parent child1 child2"
  
  # Create some radio items.
  chrome.contextMenus.create
    title: "Radio 1"
    type: "radio"
    id: "radio1"

  chrome.contextMenus.create
    title: "Radio 2"
    type: "radio"
    id: "radio2"

  console.log "radio1 radio2"
  
  # Create some checkbox items.
  chrome.contextMenus.create
    title: "Checkbox1"
    type: "checkbox"
    id: "checkbox1"

  chrome.contextMenus.create
    title: "Checkbox2"
    type: "checkbox"
    id: "checkbox2"

  console.log "checkbox1 checkbox2"
  console.log document.body

  # Intentionally create an invalid item, to show off error checking in the
  # create callback.
  console.log "About to try creating an invalid item - an error about " + "duplicate item child1 should show up"
  chrome.contextMenus.create
    title: "Oops"
    id: "child1"
  , ->
    console.log "Got expected error: " + chrome.extension.lastError.message  if chrome.extension.lastError


