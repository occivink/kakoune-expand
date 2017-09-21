# kakoune-expand

[kakoune](http://kakoune.org) plugin to select increasingly larger regions of text using a single command. Largely inspired by [Delapouite](https://github.com/delapouite)'s [expand-region](https://github.com/delapouite/kakoune-expand-region). This plugin should be mostly seen as an alternative implementation.

See this [asciinema](https://asciinema.org/a/138326) for a quick demo.

## Install

Add `expand.kak` to your autoload dir: `~/.config/kak/autoload/`, or source it manually.

## Usage

Simply call the `expand` command to select the smallest region that is bigger than the current. You can also call `expand-repeat` to enter "expand-mode" where pressing `<space>` will trigger an expansion. Pressing `<esc>` will exit this mode.

It is possible to configure the expansion commands that are run by modifying the option `expand_commands`. 
The default value (documented below) should be suitable for C-style languages. Be mindful of double expansion.
```
declare-option str expand_commands %{
    expand-impl 'exec <a-a>b'                            # parentheses
    expand-impl 'exec <a-a>B'                            # braces
    expand-impl 'exec <a-a>r'                            # brackets
    expand-impl 'exec <a-i>i'                            # indent
    expand-impl 'exec \'<a-:><a-;>k<a-K>^$<ret><a-i>i\'' # next ident level (upward)
    expand-impl 'exec \'<a-:>j<a-K>^$<ret><a-i>i\''      # next ident level (downward)
    expand-impl 'select-indented-paragraph'              # paragraph with the same indent
}
```

I suggest the following mappings:
```
map global user e :expand<ret>
map global user E :expand-repeat<ret>
```

## License

Unlicense
