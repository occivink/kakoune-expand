# kakoune-expand

[kakoune](http://kakoune.org) plugin to select increasingly larger regions of text using a single command. Largely inspired by [Delapouite](https://github.com/delapouite)'s [expand-region](https://github.com/delapouite/kakoune-expand-region). This plugin should be mostly seen as an alternative implementation.

[![demo](https://asciinema.org/a/138326.png)](https://asciinema.org/a/138326)

## Setup

Add `expand.kak` to your autoload dir: `~/.config/kak/autoload/`, or source it manually.

You need at least Kakoune v2019.01.20 to use this plugin.

## Usage

Simply call the `expand` command to select the smallest region that is bigger than the current.

It is possible to configure the expansion commands that are run by modifying the option `expand_commands`. 
The default value (documented below) should be suitable for C-style languages. Be mindful of double expansion.
```
declare-option str expand_commands %{
    expand-impl %{ exec <a-a>b }
    expand-impl %{ exec <a-a>B }
    expand-impl %{ exec <a-a>r }
    expand-impl %{ exec <a-i>i }
    expand-impl %{ exec '<a-:><a-;>k<a-K>^$<ret><a-i>i' } # previous indent level (upward)
    expand-impl %{ exec '<a-:>j<a-K>^$<ret><a-i>i' }      # previous indent level (downward)
}
```

I suggest the following mappings:
```
map -docstring "expand" global user e ': expand<ret>'

# 'lock' mapping where pressing <space> repeatedly will expand the selection
declare-user-mode expand
map -docstring "expand" global expand <space> ': expand<ret>'
map -docstring "expand ↻" global user E       ': expand; enter-user-mode -lock expand<ret>'
```

## License

Unlicense
