fs = require 'fs'
path = require 'path'
childProcess = require 'child_process'
{isArray} = require 'underscore'
{MessagePanelView, PlainMessageView} = require 'atom-message-panel'

CONFIG_FILENAME = '.atom-build.json'
STATUS_BUILDING = 'building'
STATUS_SUCCESS = 'success'
STATUS_ERROR = 'error'

buildConfigs =
  instantBuild: (root) ->
    configPath = path.join root, CONFIG_FILENAME
    try
      delete require.cache[configPath]
      require configPath
    catch e
      false

locateBuildConfig = (root) ->
  new Promise((resolve, reject) ->
    for own key, parser of buildConfigs
      if config = parser(root)
        return resolve({root, config})

    return reject('No valid configuration file found')
  )

parseBuildConfig = ({root, configPath}) ->
  try
    delete require.cache[configPath]
    config = require configPath
    Promise.resolve({root, config})
  catch e
    Promise.reject(e)

build = ({root, config}) ->
  cmd = config.cmd
  cmd = cmd.join(' ') if isArray(cmd)
  cmd += config.args.join(' ') if isArray(config.args)

  Builder.setStatus STATUS_BUILDING, 'Building&hellip;'

  return new Promise((resolve, reject) ->
    childProcess.exec(cmd, {
      env: config.env,
      cwd: root,
      shell: config.sh || config.shell
    }, (err, stdout, stderr) ->

      if err
        return reject({err, stdout, stderr})

      resolve(true)
    )
  )

startBuild = (args) ->
  build(args).then(showBuildSuccess, showBuildError)

showBuildSuccess = () ->
  Builder.setStatus STATUS_SUCCESS, 'Build finished'

showBuildError = (arg) ->
  return if not arg

  {err, stdout, stderr} = arg
  Builder.setStatus STATUS_ERROR, 'Build failed'
  Builder.setErrorMessage(stderr or stderr)

showError = (message) ->
  Builder.setStatus STATUS_ERROR, 'Build failed'
  Builder.setErrorMessage message

iconForStatus = (status) ->
  switch status
    # when STATUS_BUILDING then 'icon-zap'
    when STATUS_SUCCESS then 'icon-check'
    when STATUS_ERROR then 'icon-x'

currentBuilds = {}
module.exports = Builder =
  setStatusBarView: (@statusBarView) ->

  setStatus: (status, message, silent) ->
    @statusBarView.setStatusIcon(iconForStatus(status))
    @statusBarView.setStatus(
      status,
      message,
      resetAfterTimeout: status isnt STATUS_BUILDING
    )
    @statusBarView.setSpinnerVisibility(if status is STATUS_BUILDING then 'show' else 'hide')

    @messagePanel?.close() if not silent

  setErrorMessage: (message) ->
    if not @messagePanel
      @messagePanel = new MessagePanelView(
        title: 'Build failed'
      )

    @messagePanel.clear()
    @messagePanel.attach()

    @messagePanel.add(new PlainMessageView({
      message,
      className: 'text-error'
    }))

  build: (projectRoot) ->
    return if currentBuilds[projectRoot]

    currentBuilds[projectRoot] = true
    buildFinished = () ->
      currentBuilds[projectRoot] = false

    locateBuildConfig(projectRoot)
    .then(startBuild, showError)
    .then(buildFinished, buildFinished)
