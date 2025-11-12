# astudio.nvim

**astudio.nvim** is a Neovim plugin that streamlines Android development by integrating Gradle, Android Virtual Devices (AVD), and Android Debug Bridge (ADB) directly into your editor.

## Features

- **Gradle Integration:** Run Gradle tasks and view output in Neovim.
- **AVD Management:** List and start Android Virtual Devices from commands or Lua.
- **ADB Utilities:** Run ADB commands and interact with devices via commands or Lua.
- **Command Palette:** Access features via custom Neovim commands.
- **Lua API:** Programmatically control AVD and ADB from your config or plugins.

NOTE: This plugin does not add support for Kotlin. Please refer to the official [Kotlin Language Server](https://github.com/Kotlin/kotlin-lsp/).

## Requirements

- Neovim 0.7
- `ANDROID_USER_HOME` and `ANSROID_HOME` environment variables set. Please refer to the [official documentation](https://developer.android.com/tools/variables).
- The `android-commandlinetools` installed (`brew install android-commandlinetools`)
- Emulator and platform-tools installed (`sdkmanager emutlator platform-tools`)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  'Marfien/astudio.nvim',
  cmd = "Android",
  opts = {},
}
```

## Commands

- `:Android avd <create|launch|delete>` \
  Manages Android Virtual Devices

- `:Android install` \
  Installs the Activity onto an AVD

- `:Android uninstall` \
  Removes the Activity from an AVD \
  NOTE: Not implemented, yet

- `:Android logcat` \
  Attaches to the Activities logs

- `:Android focus` \
  Focuses the output window again

## Lua Interface

There is a shallow wrapper around the AVD and ADB CLI tools:

```lua
local avd = require('astudio-nvim.avd')
local adb = require('astudio-nvim.adb')
```

All functions within are annotated with type hints. The names should speak for them self.

## Contributing

Issues and pull requests are welcome!

## License

MIT License. See [LICENSE](./LICENSE) for details.
