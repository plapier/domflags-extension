console.log "inject.js"
console.log $('[domflag]')

chrome.runtime.sendMessage
  greeting: "hello"
, (response) ->
  console.log response.farewell

