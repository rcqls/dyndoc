url = require 'url'

dyndoc_viewer = null
DyndocViewer = null # Defer until used
renderer = require './render-dyndoc' # Defer until used

createDyndocViewer = (state) ->
  DyndocViewer ?= require './dyndoc-viewer'
  dyndoc_viewer = new DyndocViewer(state)

isDyndocViewer = (object) ->
  DyndocViewer ?= require './dyndoc-viewer'
  object instanceof DyndocViewer

deserializer =
  name: 'DyndocViewer'
  deserialize: (state) ->
    createDyndocViewer(state) if state.constructor is Object
atom.deserializers.add(deserializer)

module.exports =
  configDefaults:
    breakOnSingleNewline: false
    liveUpdate: true
    grammars: [
      'text.plain'
    ]

  activate: ->
    atom.workspaceView.command "dyndoc-viewer:eval", =>
      @eval()

    atom.workspaceView.command 'dyndoc-viewer:toggle', =>
      @toggle()

    atom.workspaceView.on 'dyndoc-viewer:preview-file', (event) =>
      @previewFile(event)

    atom.workspaceView.command 'dyndoc-viewer:toggle-break-on-single-newline', ->
      atom.config.toggle('dyndoc-viewer.breakOnSingleNewline')

    atom.workspace.registerOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'dyndoc-viewer:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        createDyndocViewer(editorId: pathname.substring(1))
      else
        createDyndocViewer(filePath: pathname)

  eval: ->
    selection = atom.workspace.getActiveEditor().getSelection()
    text = selection.getText()
    dyndoc_viewer.renderDyndocText(text)
    #res = renderer.toText text, "toto", (error, content) ->
    #  if error
    #    console.log "err: "+content
    #  else
    #   console.log "echo:" + content

  toggle: ->
    if isDyndocViewer(atom.workspace.activePaneItem)
      atom.workspace.destroyActivePaneItem()
      return

    editor = atom.workspace.getActiveEditor()
    return unless editor?

    #grammars = atom.config.get('dyndoc-viewer.grammars') ? []
    #return unless editor.getGrammar().scopeName in grammars

    @addPreviewForEditor(editor) unless @removePreviewForEditor(editor)

  uriForEditor: (editor) ->
    "dyndoc-viewer://editor/#{editor.id}"

  removePreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    console.log(uri)
    previewPane = atom.workspace.paneForUri(uri)
    console.log("preview-pane: "+previewPane)
    if previewPane?
      previewPane.destroyItem(previewPane.itemForUri(uri))
      true
    else
      false

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (DyndocViewer) ->
      if isDyndocViewer(DyndocViewer)
        #DyndocViewer.renderDyndoc()
        previousActivePane.activate()

  previewFile: ({target}) ->
    filePath = $(target).view()?.getPath?()
    return unless filePath

    for editor in atom.workspace.getEditors() when editor.getPath() is filePath
      @addPreviewForEditor(editor)
      return

    atom.workspace.open "dyndoc-viewer://#{encodeURI(filePath)}", searchAllPanes: true
