try %{
    require-module expand
} catch %{
    source expand.kak
    require-module expand
}

define-command assert-selections-are -params 1 %{
    eval %sh{
        if [ "$1" != "$kak_quoted_selections" ]; then
            printf 'fail "Check failed"'
        fi
    }
}

edit -scratch *expand-test-1*

exec 'i[{(abc)}]<esc>'
exec '/abc<ret>'
assert-selections-are "'abc'"
expand
assert-selections-are "'(abc)'"
expand
assert-selections-are "'{(abc)}'"
expand
assert-selections-are "'[{(abc)}]'"

exec 'gg/\(<ret>'
expand
assert-selections-are "'(abc)'"

exec 'gg/\{<ret>'
expand
assert-selections-are "'{(abc)}'"

exec 'gg/\[<ret>'
expand
assert-selections-are "'[{(abc)}]'"

delete-buffer

edit -scratch *expand-test-2*

exec 'iabc<esc>'
exec 'o    abc<esc>'
exec 'xypp'
exec 'geoabc<esc>'
exec 'ggjj'

expand
assert-selections-are \
"'    abc
    abc
    abc
'"

exec 'gg'
expand
assert-selections-are \
"'abc
    abc
    abc
    abc
abc
'"

delete-buffer

#TODO test multi-selection
