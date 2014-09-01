path = require 'path'

{$, $$$, ScrollView} = require 'atom'
_ = require 'underscore-plus'
fs = require 'fs-plus'
{File} = require 'pathwatcher'

renderer = require './render-dyndoc'

module.exports =
class DyndocViewer extends ScrollView
  @content: ->
    @div class: 'dyndoc-viewer native-key-bindings', tabindex: -1, =>

  constructor: ({@editorId, filePath}) ->
    super

    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        @subscribeToFilePath(filePath)
      else
        @subscribe atom.packages.once 'activated', =>
          @subscribeToFilePath(filePath)

  serialize: ->
    deserializer: 'DyndocViewer'
    filePath: @getPath()
    editorId: @editorId

  destroy: ->
    @unsubscribe()

  subscribeToFilePath: (filePath) ->
    @file = new File(filePath)
    @trigger 'title-changed'
    @handleEvents()
    #@renderDyndoc()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)
      if @editor?
        @trigger 'title-changed' if @editor?
        @handleEvents()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        @parents('.pane').view()?.destroyItem(this)

    if atom.workspace?
      resolve()
    else
      @subscribe atom.packages.once 'activated', =>
        resolve()
        #@renderDyndoc()

  editorForId: (editorId) ->
    for editor in atom.workspace.getEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: ->
    #@subscribe atom.syntax, 'grammar-added grammar-updated', _.debounce((=> @renderDyndoc()), 250)
    @subscribe this, 'core:move-up', => @scrollUp()
    @subscribe this, 'core:move-down', => @scrollDown()

    @subscribeToCommand atom.workspaceView, 'dyndoc-viewer:zoom-in', =>
      zoomLevel = parseFloat(@css('zoom')) or 1
      @css('zoom', zoomLevel + .1)

    @subscribeToCommand atom.workspaceView, 'dyndoc-viewer:zoom-out', =>
      zoomLevel = parseFloat(@css('zoom')) or 1
      @css('zoom', zoomLevel - .1)

    @subscribeToCommand atom.workspaceView, 'dyndoc-viewer:reset-zoom', =>
      @css('zoom', 1)

    changeHandler = =>
      #@renderDyndoc()
      pane = atom.workspace.paneForUri(@getUri())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    if @file?
      @subscribe(@file, 'contents-changed', changeHandler)
    else if @editor?
      @subscribe @editor.getBuffer(), 'contents-modified', =>
        changeHandler() if atom.config.get 'dyndoc-viewer.liveUpdate'
      @subscribe @editor, 'path-changed', => @trigger 'title-changed'
      @subscribe @editor.getBuffer(), 'reloaded saved', =>
        changeHandler() unless atom.config.get 'dyndoc-viewer.liveUpdate'

    @subscribe atom.config.observe 'dyndoc-viewer.breakOnSingleNewline', callNow: false, changeHandler

  renderDyndoc: ->
    #@showLoading()
    if @file?
      @file.read().then (contents) => @renderDyndocText(contents)
    else if @editor?
      @renderDyndocText(@editor.getText())

  renderDyndocText: (text) ->
    console.log("text:"+text)
    renderer.toText text, @getPath(), (error, content) =>
      if error
        alert(content)
      else
        @loading = false
        console.log('content:'+content)
        @html(content)
        @trigger('dyndoc-viewer:dyndoc-changed')

  getTitle: ->
    if @file?
      "#{path.basename(@getPath())} Preview"
    else if @editor?
      "#{@editor.getTitle()} Preview"
    else
      "Dyndoc Preview"

  getIconName: ->
    "dyndoc"

  getUri: ->
    if @file?
      "dyndoc-viewer://#{@getPath()}"
    else
      "dyndoc-viewer://editor/#{@editorId}"

  getPath: ->
    if @file?
      @file.getPath()
    else if @editor?
      @editor.getPath()

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Previewing dyndoc Failed'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @loading = true
    @html $$$ ->
      @div class: 'dyndoc-spinner', 'Loading dyndoc\u2026'
