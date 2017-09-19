# increases the size of the current selection by repeatedly calling "expand"

# exclude text objects with symetric delimiters as they yield too many false positives
declare-option str expand_commands %{
    expand-impl 'exec <a-a>b'
    expand-impl 'exec <a-a>B'
    expand-impl 'exec <a-a>r'
    expand-impl 'exec <a-i>i'
    expand-impl 'exec \'<a-:><a-;>k<a-K>^$<ret><a-i>i\''
    expand-impl 'exec \'<a-:>j<a-K>^$<ret><a-i>i\''
    expand-impl 'select-indented-paragraph'
}

declare-option -hidden str-list expand_results

define-command expand-repeat %{
    expand
    info "Expanding"
    on-key %{ %sh{
        if [ $kak_key = "<space>" ]; then
            echo expand-repeat
        else
            echo "exec <esc>"
        fi
    }}
}

define-command expand %{
    eval -no-hooks -itersel %{
        exec <a-:>
        unset-option buffer expand_results
        eval %opt{expand_commands}
        # compare the results and take the best
        %sh{
            # returns 0 if $1 is a strict superset of $2
            compare_descs() {
                if [ $1 = $2 ]; then
                    return 1
                fi
                #999 columns ought to be enough for anybody
                start_1=${1%,*}
                start_1=$(printf "%d%03d" ${start_1%.*} ${start_1#*.})
                end_1=${1#*,}
                end_1=$(printf "%d%03d" ${end_1%.*} ${end_1#*.})
                start_2=${2%,*}
                start_2=$(printf "%d%03d" ${start_2%.*} ${start_2#*.})
                end_2=${2#*,}
                end_2=$(printf "%d%03d" ${end_2%.*} ${end_2#*.})
                if [ $start_1 -le $start_2 ] && [ $end_1 -ge $end_2 ]; then
                    return 0
                else
                    return 1
                fi
            }
            # iterate over the candidates, and take the smallest selection
            # that is bigger than the current
            init_desc=$kak_selection_desc
            best_desc=0.0,9999999.999
            best_length=9999999
            IFS=:
            for current in $kak_opt_expand_results; do
                desc=${current%_*}
                length=${current#*_}
                if compare_descs $desc $init_desc && [ $length -lt $best_length ]; then
                    best_desc=$desc
                    best_length=$length
                fi
            done
            printf "select %s\n" "$best_desc"
        }
    }
}

define-command expand-impl -hidden -params 1 %{
    eval -no-hooks -draft -save-regs 'd/' %{
        try %{
            eval %arg{1}
            set-register d %val{selection_desc}
            exec s.<ret>
            set-option -add buffer expand_results "%reg{d}_%reg{#}"
        }
    }
}

define-command -hidden select-indented-paragraph %{
    exec -draft -save-regs '' '<a-i>pZ'
    exec '<a-i>i<a-z>i'
}