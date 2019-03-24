# increases the size of the current selection by repeatedly calling "expand"

# exclude text objects with symetric delimiters as they yield too many false positives
declare-option str expand_commands %{
    expand-impl %{ exec <a-a>b }
    expand-impl %{ exec <a-a>B }
    expand-impl %{ exec <a-a>r }
    expand-impl %{ exec <a-i>i }
    expand-impl %{ exec '<a-:><a-;>k<a-K>^$<ret><a-i>i' }
    expand-impl %{ exec '<a-:>j<a-K>^$<ret><a-i>i' }
}

declare-option -hidden str-list expand_shrink_results

define-command expand -docstring "
Expand the current selection til the next semantic block
" %{
    eval -itersel %{
        exec <a-:>
        unset-option buffer expand_shrink_results
        eval %opt{expand_commands}
        # compare the results and take the best
        select %sh{
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
            best_desc=1.1,9999999.999
            best_length=9999999
            IFS=:
            eval set -- "$kak_opt_expand_shrink_results"
            for current in "$@"; do
                desc=${current%_*}
                length=${current#*_}
                if compare_descs $desc $init_desc && [ $length -lt $best_length ]; then
                    best_desc=$desc
                    best_length=$length
                fi
            done
            printf "%s" "$best_desc"
        }
    }
}

define-command expand-impl -hidden -params 1 %{
    eval -draft -save-regs '/"|^@' %{
        try %{
            eval %arg{1}
            set -add buffer expand_shrink_results "%val{selection_desc}_%val{selection_length}"
        }
    }
}


declare-option str-list shrink_commands \
    %{ exec <a-s> } \
    %{ exec 's\{.*?\}<ret>' } \
    %{ exec 's\[.*?\]<ret>' } \
    %{ exec 's<lt>.*?><ret>' } \
    %{ exec '1S\n(\n+)<ret>' } \
    %{ exec 's\w+<ret>' } \
    %{ exec '<a-X>' } \

def shrink %{
    shrink-impl %opt{shrink_commands}
}

def shrink-impl -hidden -params .. %{
    unset buffer expand_shrink_results
    eval -no-hooks -itersel %sh{
        # add delimiters to know where we're at when iterating

        printf 'set -add buffer expand_shrink_results %%val{selection_desc}\n'
        while [ $# -gt 0 ]; do
            printf 'shrink-unit-impl %%arg{%s}\n' $#
            shift
        done
        printf 'set -add buffer expand_shrink_results SELECTION\n'
    }
    eval select %sh{
        # returns 0 if $1 is a strict subset of $2
        is_subset() {
            lhs_beg=${1%,*}
            lhs_beg=$(( ${lhs_beg%.*} * 1000 + ${lhs_beg#*.} ))
            lhs_end=${1#*,}
            lhs_end=$(( ${lhs_end%.*} * 1000 + ${lhs_end#*.} ))
            if [ $lhs_end -lt $lhs_beg ]; then
                tmp=$lhs_end
                lhs_end=$lhs_beg
                lhs_beg=$tmp
            fi
            rhs_beg=${2%,*}
            rhs_beg=$(( ${rhs_beg%.*} * 1000 + ${rhs_beg#*.} ))
            rhs_end=${2#*,}
            rhs_end=$(( ${rhs_end%.*} * 1000 + ${rhs_end#*.} ))
            if [ $rhs_end -lt $rhs_beg ]; then
                tmp=$rhs_end
                rhs_end=$rhs_beg
                rhs_beg=$tmp
            fi
            if [ $lhs_beg -gt $rhs_beg ] && [ $lhs_end -le $rhs_end ]; then
                return 0
            elif [ $lhs_beg -ge $rhs_beg ] && [ $lhs_end -lt $rhs_end ]; then
                return 0
            fi
            return 1
        }

        input_desc=""
        best_desc=""
        best_length=0

        result_desc=""
        result_max_length=0

        # each input selection produces multiple results, and each result contains multiple selections
        # we decide which result to keep using the selection length: the result that contains the longest selection is accepted

        # in order we should see ($input_desc (($desc $length)* RESULT)* SELECTION)*
        eval set -- "$kak_opt_expand_shrink_results"
        while [ $# -gt 0 ]; do
            if [ "$input_desc" = "" ]; then
                input_desc="$1"
            elif [ "$1" = SELECTION ]; then
                if [ "$best_length" -gt 0 ]; then
                    printf ' %s' "$best_desc"
                fi
                input_desc=""
                best_length=0
                best_desc=""
            elif [ "$1" = RESULT ]; then
                # finished parsing a result, check if it replaces the best
                if [ $result_max_length -gt $best_length ]; then
                    best_desc=$result_desc
                    best_length=$result_max_length
                fi
                result_desc=""
                result_max_length=0
            else
                desc="$1"
                shift
                if is_subset $desc $input_desc; then
                    length=$1
                    result_desc="$result_desc $desc"
                    if [ $length -gt $result_max_length ]; then
                        result_max_length=$length
                    fi
                fi
            fi
            shift
        done
    }
}

def shrink-unit-impl -hidden -params 1 %{
    eval -no-hooks -draft -save-regs '/"|^@' %{
        try %{
            eval -no-hooks %arg{1}
            eval -no-hooks -itersel %{
                set -add buffer expand_shrink_results %val{selection_desc} %val{selection_length}
            }
            set -add buffer expand_shrink_results RESULT
        }
    }
}
