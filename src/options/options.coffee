$ ->
  autoInspectOpen   = document.getElementById("autoInspectOpen")
  autoInspectReload = document.getElementById("autoInspectReload")
  hideEmptyPanel    = document.getElementById("hideEmptyPanel")

  save_options = ->
    chrome.storage.local.set
      autoInspectOpen: autoInspectOpen.checked
      autoInspectReload: autoInspectReload.checked
      hideEmptyPanel: hideEmptyPanel.checked

  restore_options = ->
    chrome.storage.local.get
      autoInspectOpen: true
      autoInspectReload: true
      hideEmptyPanel: false
    , (items) ->
      autoInspectOpen.checked  = items.autoInspectOpen
      autoInspectReload.checked = items.autoInspectReload
      hideEmptyPanel.checked = items.hideEmptyPanel


  restore_options()
  $('form').on 'click', 'input', ->
    save_options()
