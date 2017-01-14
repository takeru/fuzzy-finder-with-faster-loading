{$} = require 'atom-space-pen-views'
{Disposable, CompositeDisposable} = require 'atom'
humanize = require 'humanize-plus'
fs = require 'fs-plus'
path = require 'path'

FuzzyFinderView = require './fuzzy-finder-view'
PathLoader = require './path-loader'

module.exports =
class ProjectView extends FuzzyFinderView
  paths: null
  reloadPaths: true
  reloadAfterFirstLoad: false

  initialize: (@paths) ->
    super

    @disposables = new CompositeDisposable
    @reloadPaths = false if @paths?.length > 0
    @watchedPaths = []

    @setupPackagePathWatchers()

    @subscribeToConfig()

    @disposables.add atom.project.onDidChangePaths =>
      @reloadPaths = true
      @paths = null
      @setupPackagePathWatchers()

    if !@paths
      @tryLoadCachedProjectFiles()

  setupPackagePathWatchers: ->
    for watcher in @watchedPaths
      watcher.close()
    @watchedPaths = atom.project.getPaths().map((projectPath) =>
      fs.watch(
        fs.realpathSync(projectPath),
        { recursive: true, persistent: false },
        (eventType, fileName) => @projectFileChanged(eventType, fileName)
      )
    )

  projectFileChanged: (eventType, fileName) -> 
    if eventType != 'change'
      @queueReload()

  queueReload: ->
    if @paths?
        @reloadPaths = true
    else
      # The update happened while the first task was still running
      # so let it complete but reload the paths on the next populate call.
      @reloadAfterFirstLoad = true

  subscribeToConfig: ->
    @disposables.add atom.config.onDidChange 'fuzzy-finder.ignoredNames', =>
      @reloadPaths = true

    @disposables.add atom.config.onDidChange 'core.followSymlinks', =>
      @reloadPaths = true

    @disposables.add atom.config.onDidChange 'core.ignoredNames', =>
      @reloadPaths = true

    @disposables.add atom.config.onDidChange 'core.excludeVcsIgnoredPaths', =>
      @reloadPaths = true

  toggle: ->
    if @panel?.isVisible()
      @cancel()
    else
      @populate()
      @show()

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'Project is empty'
    else
      super

  populate: ->
    @setItems(@paths) if @paths?

    if atom.project.getPaths().length is 0
      @setItems([])
      return

    if @reloadPaths
      @reloadPaths = false

      try
        task = @runLoadPathsTask =>
          if @reloadAfterFirstLoad
            @reloadPaths = true
            @reloadAfterFirstLoad = false
          @populate()
      catch error
        # If, for example, a network drive is unmounted, @runLoadPathsTask will
        # throw ENOENT when it tries to get the realpath of all the project paths.
        # This catch block allows the file finder to still operate on the last
        # set of paths and still let the user know that something is wrong.
        if error.code is 'ENOENT' or error.code is 'EPERM'
          atom.notifications.addError('Project path not found!', detail: error.message)
        else
          throw error


      if @paths?
        @setLoading("Reindexing project\u2026")
      else
        @setLoading("Indexing project\u2026")
        @loadingBadge.text('0')
        pathsFound = 0
        task?.on 'load-paths:paths-found', (paths) =>
          pathsFound += paths.length
          @loadingBadge.text(humanize.intComma(pathsFound))

  projectRelativePathsForFilePaths: ->
    projectRelativePaths = super

    if lastOpenedPath = @getLastOpenedPath()
      for {filePath}, index in projectRelativePaths
        if filePath is lastOpenedPath
          [entry] = projectRelativePaths.splice(index, 1)
          projectRelativePaths.unshift(entry)
          break

    projectRelativePaths

  getLastOpenedPath: ->
    activePath = atom.workspace.getActivePaneItem()?.getPath?()

    lastOpenedEditor = null

    for editor in atom.workspace.getTextEditors()
      filePath = editor.getPath()
      continue unless filePath
      continue if activePath is filePath

      lastOpenedEditor ?= editor
      if editor.lastOpened > lastOpenedEditor.lastOpened
        lastOpenedEditor = editor

    lastOpenedEditor?.getPath()

  destroy: ->
    @loadPathsTask?.terminate()
    @disposables.dispose()
    super

  runLoadPathsTask: (fn) ->
    @loadPathsTask?.terminate()
    @loadPathsTask = PathLoader.startTask (@paths) =>
      @reloadPaths = false
      @saveProjectData()
      fn?()

  getBaseSavePath: ->
    packagePaths = atom.packages.getPackageDirPaths()
    path.join(packagePaths[packagePaths.length - 1], 'fuzzy-finder-with-faster-loading', 'data')

  getSavePath: (projectPath) ->
    path.join(@getBaseSavePath(), projectPath.replace(/\W+/g, '_'))

  saveProjectData: ->
    if !@paths?.length
      return
    atom.project.getPaths().forEach (projectPath) =>
      projectFilesPaths = @paths.filter((p) => p.startsWith projectPath)
      fs.writeFile(@getSavePath(projectPath), JSON.stringify(projectFilesPaths), () => )

  tryLoadCachedProjectFiles: ->
    atom.project.getPaths().forEach (projectPath) =>
      try
        data = JSON.parse(fs.readFileSync(@getSavePath(projectPath), 'utf8'))
        if data?.length
          @paths = if @paths then @paths.concat(data) else data
