# Fuzzy Finder with faster loading
This is a fork of Atom [Fuzzy Finder](https://github.com/atom/fuzzy-finder) package.  
Changes in this fork:  
:rocket: project files caching: when you reopen a project, there's no need to wait for `Indexing...`  
:rocket: watching files with `fs.watch` instead of reloading everything on atom window focus  

Limitations:  
- doesn't work on Linux and in network shares, because of [fs.watch implementation](https://nodejs.org/docs/latest/api/fs.html#fs_caveats)

As long as the changes are not consistent across all OS, most probably this patch be accepted to fork, so let's leavt it here for now.

## Original readme

Quickly find and open files using <kbd>cmd-t</kbd>.

  * <kbd>cmd-t</kbd> or <kbd>cmd-p</kbd> to open the file finder
  * <kbd>cmd-b</kbd> to open the list of open buffers
  * <kbd>cmd-shift-b</kbd> to open the list of Git modified and untracked files
  * <kbd>enter</kbd> defaults to opening the selected file without leaving the current pane
  * <kbd>shift-enter</kbd> defaults to switching to another pane if the file is already open there
  * <kbd>cmd-k</kbd> <kbd>right</kbd> (or any other directional arrow) will open the highlighted file in a new pane on the side indicated by the arrow

Turning on the "Search All Panes" setting reverses the behavior of <kbd>enter</kbd> and <kbd>shift-enter</kbd> so <kbd>enter</kbd> opens the file in any pane and <kbd>shift-enter</kbd> creates a new tab in the current pane.

This package uses both the `core.ignoredNames` and `fuzzy-finder.ignoredNames` config settings to filter out files and folders that will not be shown. Both of those config settings are interpreted as arrays of [minimatch](https://github.com/isaacs/minimatch) glob patterns.

This package also will also not show Git ignored files when the `core.excludeVcsIgnoredPaths` is enabled.

![](https://f.cloud.github.com/assets/671378/2241456/100db6b8-9cd3-11e3-9b3a-569c6b50cc60.png)
