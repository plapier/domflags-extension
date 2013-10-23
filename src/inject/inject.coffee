console.log "inject.js"
# console.log $('[domflag]')
$domflags = $('[domflag]')
domCount = $domflags.length - 1
console.log domCount

for own key of $domflags
  if $.isNumeric(key)
    domTag = $domflags[key].tagName
    domArray = [domTag]
    Array::slice.call($domflags[key].attributes).forEach (item) ->
      domArray.push("#{item.name}='#{item.value}'") if item.name != "domflag"

    domString = domArray.join(' ')
    console.log domString

chrome.runtime.sendMessage
  greeting: "div.domflag"
  domCount: domCount
, (response) ->
  console.log response.farewell
