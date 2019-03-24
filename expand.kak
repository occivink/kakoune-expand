# increases the size of the current selection(s) by repeatedly calling "expand"
# or decrease their sizes by calling "shrink"

# exclude text objects with symetric delimiters as they yield too many false positives
decl str-list expand_commands \
    %{ exec <a-a>b } \
    %{ exec <a-a>B } \
    %{ exec <a-a>r } \
    %{ exec <a-i>i } \
    %{ exec <a-x> } \
    %{ exec '<a-:><a-;>k<a-K>^$<ret><a-i>i' } \
    %{ exec '<a-:>j<a-K>^$<ret><a-i>i' }

decl str-list shrink_commands \
    %{ exec <a-s> } \
    %{ exec 's\{.*?\}<ret>' } \
    %{ exec 's\[.*?\]<ret>' } \
    %{ exec 's<lt>.*?><ret>' } \
    %{ exec '1S\n(\n+)<ret>' } \
    %{ exec 's\w+<ret>' } \
    %{ exec '<a-X>' }

def expand -docstring '..' %{
    expand-shrink-impl expand %opt{expand_commands}
}

def shrink -docstring '..' %{
    expand-shrink-impl shrink %opt{shrink_commands}
}

decl -hidden str-list expand_shrink_results

def expand-shrink-impl -hidden -params .. %{
    unset buffer expand_shrink_results
    eval -no-hooks -itersel %sh{
        i=2
        printf 'set -add buffer expand_shrink_results %%val{selection_desc}\n'
        while [ $i -le $# ]; do
            printf 'expand-shrink-gen-result %%arg{%s}\n' $i
            i=$((i + 1))
        done
        # add delimiters to know where we're at when iterating
        printf 'set -add buffer expand_shrink_results SELECTION\n'
    }

    eval select %sh{
        # desc_op is used to determine if a selection is a subset/superset of another
        # length_op is used to determine if a candidate result is better than the best yet
        if [ "$1" = expand ]; then
            desc_op="-gt"
            # when expanding, we want to take the smallest result that is bigger than the current
            # so we start at 99999 and proceed if we're smaller
            length_op="-lt"
            default_length=99999
        elif [ "$1" = shrink ]; then
            desc_op="-lt"
            # when shrinking, we want to take the biggest result that is smaller than the current
            # so we start at 0 and proceed if we're bigger
            length_op="-gt"
            default_length=0
        else
            exit
        fi

        # used to determine if $1 is a valid result for $2
        # when shrinking, that means $1 is a strict subset of $2
        # when expanding, that means $1 is a strict superset of $2
        is_valid() {
            # for comparing selections, we simply encode each end as (line * 1000 + col)
            # and compare these numbers
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
            if [ $lhs_beg $desc_op $rhs_beg ]; then
                return 1
            elif [ $rhs_end $desc_op $lhs_end ]; then
                return 1
            elif [ $lhs_beg -eq $rhs_beg ] && [ $lhs_end -eq $rhs_end ]; then
                return 1
            fi
            return 0
        }

        input_desc=""
        best_desc=""
        best_length=$default_length

        result_desc=""
        result_best_length=$default_length

        # each input selection produces multiple results, and each result contains multiple selections
        # we decide which result to keep using the selection length
        # in iteration order order we should see ($input_desc (($desc $length)* RESULT)* SELECTION)*
        eval set -- "$kak_opt_expand_shrink_results"
        while [ $# -gt 0 ]; do
            if [ "$input_desc" = "" ]; then
                input_desc="$1"
            elif [ "$1" = SELECTION ]; then
                if [ "$best_length" -ne $default_length ]; then
                    printf ' %s' "$best_desc"
                fi
                input_desc=""
                best_length=$default_length
                best_desc=""
            elif [ "$1" = RESULT ]; then
                # finished parsing a result, check if it replaces the best
                if [ $result_best_length $length_op $best_length ]; then
                    best_desc=$result_desc
                    best_length=$result_best_length
                fi
                result_desc=""
                result_best_length=$default_length
            else
                desc="$1"
                shift
                if is_valid $desc $input_desc; then
                    length=$1
                    result_desc="$result_desc $desc"
                    if [ $length $length_op $result_best_length ]; then
                        result_best_length=$length
                    fi
                fi
            fi
            shift
        done
    }
}

def expand-shrink-gen-result -hidden -params 1 %{
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
