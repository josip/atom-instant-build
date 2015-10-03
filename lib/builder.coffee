fs = require 'fs'
path = require 'path'
childProcess = require 'child_process'
{extend, isArray, last} = require 'underscore'
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
  cmd += ' ' + config.args.join(' ') if isArray(config.args)

  Builder.setStatus STATUS_BUILDING, 'Building&hellip;'

  return new Promise((resolve, reject) ->
    procConfig =
      cwd: root
      env: {}
      sh: config.sh or config.shell or process.env.SHELL

    shellBuffer = new Buffer(0)
    # on OS X, .apps don't inherit users' default env variables
    shell = childProcess.spawn procConfig.sh, ['-lc', 'export'],
      detached: true,
      stdio: ['ignore', 'pipe', 'ignore']

    shell.stdout.on 'data', (data) ->
      shellBuffer = Buffer.concat([shellBuffer, data])

    shell.on 'close', () ->
      #
      # /bin/bash -lc export looks like:
      # declare -x VAR_NAME="value"
      #
      # while for /bin/sh its:
      # export VAR_NAME="value"
      #
      # and for zsh it's ofc different:
      # ENV_NAME=vlaue
      #
      for row in shellBuffer.toString().trim().split('\n')
        [k, v] = row.split('=', 2)
        k = last(k.split(' '))
        if v?.length and v[0] is '"' and last(v) is '"'
          v = v.slice(1, -1)

        procConfig.env[k] = v

      extend(procConfig.env, config.env || {})

      childProcess.exec(cmd, procConfig, (err, stdout, stderr) ->
        if err then reject({err, stdout, stderr}) else resolve(true)
      )
  )

startBuild = (args) ->
  build(args)
    .then(showBuildSuccess, showBuildError)

showBuildSuccess = () ->
  Builder.setStatus STATUS_SUCCESS, 'Build finished'

showBuildError = (arg) ->
  return if not arg

  {err, stdout, stderr} = arg
  Builder.setStatus STATUS_ERROR, 'Build failed'
  Builder.setErrorMessage(stdout or stderr)

showError = (message) ->
  Builder.setStatus STATUS_ERROR, 'Build failed'
  Builder.setErrorMessage message

iconForStatus = (status) ->
  switch status
    # when STATUS_BUILDING then 'icon-zap'
    when STATUS_SUCCESS then 'icon-check'
    when STATUS_ERROR then 'icon-x'

currentBuild = null
buildTimes = {}
module.exports = Builder =
  setStatusBarView: (@statusBarView) ->

  setStatus: (status, message, silent) ->
    @statusBarView.setStatusIcon(iconForStatus(status))
    @statusBarView.setStatus(
      status,
      message,
      resetAfterTimeout: status isnt STATUS_BUILDING
    )
    if status is STATUS_BUILDING
      @statusBarView.animateProgressBar(buildTimes[currentBuild])
      @statusBarView.setSpinnerVisibility('show')
    else
      @statusBarView.setSpinnerVisibility('hide')

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
    return if currentBuild

    currentBuild = projectRoot
    startedAt = Date.now()

    buildFinished = () ->
      currentBuild = null
      buildTimes[projectRoot] = Date.now() - startedAt

    locateBuildConfig(projectRoot)
    .then(startBuild, showError)
    .then(buildFinished, buildFinished)
