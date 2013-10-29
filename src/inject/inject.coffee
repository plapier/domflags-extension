console.log "inject.js"
$domflags = $('[domflag]')

flagElements = []
for own key of $domflags
  if $.isNumeric(key)
    domTag = $domflags[key].tagName
    domArray = [domTag]
    Array::slice.call($domflags[key].attributes).forEach (item) ->
      domArray.push("#{item.name}='#{item.value}'") if item.name != "domflag"

    domString = domArray.join(' ')
    flagElements.push(domString)

chrome.runtime.sendMessage
  flags: flagElements

## Receive request for flags. Send flags to background.js
chrome.runtime.onMessage.addListener (message, sender, sendResponse) ->
  sendResponse flags: flagElements
