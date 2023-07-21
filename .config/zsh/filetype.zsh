function filetype() {
    alias -s $1=$2
}

# turn an array of (1 2 1 2) into ( (1 2) (1 2) )
# then execute function provided as $1 on them
function make_pairs() {
    local -a pair
    local -a array
    array=("${@:2}")
    for (( i=1; i < $#; i+=2 )); do
        pair=("${array[$i]}" "${array[$i+1]}")
        "$1" "${pair[@]}"
    done
}

_editor_fts=(cpp cxx cc c hh h inl asc txt TXT tex rs lua py js ts css html)
_editor_array=($EDITOR)
make_pairs filetype "${_editor_fts[@]:^^_editor_array}"

_browser_fts=(htm html de org net com at cx nl se dk)
_browser_array=($BROWSER)
make_pairs filetype "${_browser_fts[@]:^^_browser_array}"

_media_fts=(ape avi flv m4a mkv mov mp3 mpeg mpg ogg ogm rm wav webm)
_mplayer_array=(mplayer)
make_pairs filetype "${_media_fts[@]:^^_mplayer_array}"
