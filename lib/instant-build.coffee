{CompositeDisposable} = require 'atom'
path = require 'path'
Builder = require './builder'
StatusBarView = require './status-bar-view'

module.exports = instantBuild =
  subscriptions: null

  config:
    buildOnSave:
      title: 'Build on save'
      type: 'boolean'
      default: true

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'instant-build:build': => @build()
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave () =>
        @build() if atom.config.get('instant-build.buildOnSave')

    @statusBarView = new StatusBarView(state.statusBarView)
    Builder.setStatusBarView @statusBarView

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addLeftTile(
      item: @statusBarView.getElement(),
      priority: -1
    )

  deactivate: ->
    @subscriptions.dispose()

    Builder.messagePanel?.close()

    @statusBarView?.destroy()
    Builder.setStatusBarView(@statusBarView = null)

    @statusBarTile?.destroy()
    @statusBarTile = null

  serialize: ->
    statusBarView: @statusBarView?.serialize()

  build: ->
    editor = atom.workspace.getActivePaneItem()
    file = editor?.buffer?.file
    return unless file

    filePath = file.path
    projectDirectory = atom.project.getDirectories().filter((dir) ->
      dir.contains(filePath))

    return unless projectDirectory.length

    if projectDirectoryPath = projectDirectory[0].path
      Builder.build(projectDirectoryPath)
