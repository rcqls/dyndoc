url = require 'url'

dyndoc_viewer = null
DyndocViewer = require './dyndoc-viewer' #null # Defer until used
rendererCoffee = require './render-coffee'
rendererDyndoc = require './render-dyndoc'

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
    localServer: true
    localServerUrl: 'localhost'
    localServerPort: 7777
    remoteServerUrl: 'sagag6.upmf-grenoble.fr'
    remoteServerPort: 5555
    breakOnSingleNewline: false
    liveUpdate: true
    grammars: [
      'source.dyndoc'
      'source.gfm'
      'text.html.basic'
      'text.html.textile'
    ]

  activate: ->
    atom.workspaceView.command "dyndoc-viewer:eval", =>
      @eval()

    atom.workspaceView.command "dyndoc-viewer:atom-dyndoc", =>
      @atomDyndoc()

    atom.workspaceView.command "dyndoc-viewer:coffee", =>
      @coffee()

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

  coffee: ->
    selection = atom.workspace.getActiveEditor().getSelection()
    text = selection.getText()
    console.log rendererCoffee.eval text

  atomDyndoc: ->
    selection = atom.workspace.getActiveEditor().getSelection()
    text = selection.getText()
    if text == ""
      text = atom.workspace.getActiveEditor().getText()
    #util = require 'util'
    #console.log util.inspect text
    text='[#require]Tools/Atom\n[#main][#>]{#atomInit#}\n'+text
    rendererDyndoc.eval text, atom.workspace.getActiveEditor().getPath(), (error, content) ->
      if error
        console.log "err: "+content
      else
        #console.log "before:" + content
        content=content.replace /__DIESE_ATOM__/g, '#'
        content=content.replace /__AROBAS_ATOM__\{/g, '#{'

        #console.log "echo:" + content
        #fs = require "fs"
        #fs.writeFile "/Users/remy/test_atom.coffee", content, (error) ->
        #  console.error("Error writing file", error) if error
        rendererCoffee.eval content

  eval: ->
    return unless dyndoc_viewer
    selection = atom.workspace.getActiveEditor().getSelection()
    text = selection.getText()
    if text == ""
      text = atom.workspace.getActiveEditor().getText()
    dyndoc_viewer.render(text)
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
