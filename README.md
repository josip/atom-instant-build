# instant-build

A dead simple and instantly fast way of launching your build system straight from [Atom](https://atom.io).

## Features

* Runs instantly<sup>1</sup>
* Supports multiple project folders
* Build-on-save
* Can be easily integrated with any build system
* No Google Analytics business

![demo](http://cl.ly/image/471V0B3H3g06/Screen%20Recording%202015-09-30%20at%2008.38%20AM.gif)

## Install

```
apm install instant-build
```

You can start the build by either searching for "Instant build" in your command panel or via `Command-B`.

## Configuration

`instant-build` currently requires a `.atom-build.json` file at the root of your project.
File format is compatible with that of [atom-build](https://github.com/noseglid/atom-build),
just with less options.

```js
{
  // [required] command to execute, it can be either a string or an array, in any case it can contain command's arguments
  "cmd": "command --to execute",
  // [optional] name of the build system (for future use)
  "name": "Build system's name",
  // [optional] if provided arguments here will be appended to the command
  "args": ["--this=is-optional", "--and=will-be-joined"],
  // [optional] environment variables to be passed to the command
  "env": {
    "VAR1": "1",
    "VAR2": "2"
  },
  // [optional] shell to execute the command with (default: /bin/sh)
  "shell": "/bin/sh"
}
```

---

<sup>1</sup> &mdash; invokes your build system instantly, actual build time may vary
