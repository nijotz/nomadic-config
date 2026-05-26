# Nomadic Config

This is a [nomadic](https://github.com/nijotz/nomadic) configuration repo — a portable shell environment you can apply on any machine.

## Structure

```
modules/          One directory per module
  <name>/
    bash          Shell config sourced into .bashrc (or zsh for .zshrc)
    bash.macos    OS-specific variant (loaded instead of bash on macOS)
    deps          Module metadata: ordering (after:), packages (pkg:), OS filter (os:)
    links         Symlink mappings: <source> <target> (~ expanded in target)
    setup         Script run once during apply
packages/         Base package lists installed on every apply
profiles/         Named sets of modules to enable/disable per machine
```

## Usage

```bash
# Apply this config on a new machine
nomadic apply <path-or-git-url>

# Re-apply after making changes
nomadic apply
```

See `nomadic help` for all commands.
