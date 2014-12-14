#!/usr/bin/env zsh
PATH="/bin:/usr/bin"
PORT=${1=8080}
DEFAULT_ROOT=$(cd $(dirname $0); pwd)
PROJECT_ROOT=$PWD
FILE_INDEX="index.html"
LOG_FORMAT="\$TIMESTAMP \$METHOD \$REQUEST_PATH \$USER_AGENT"

if [ -e "${PROJECT_ROOT}"/404.html ];then
    FILE_404="${PROJECT_ROOT}"/"404.html"
else
    FILE_404="${DEFAULT_ROOT}"/"404.html"
fi

header_begin(){
    case $1 in
        200) echo "HTTP/1.1 200 OK";;
        404) echo "HTTP/1.1 404 NotFound";;
    esac
}

content_type(){
    echo "Content-Type: $1"
}
content_type_of(){
    echo "Content-Type: $(mimetype -b $1)"
}

header_end(){
    echo
}

render_file(){
    cat "$1" |
	sed -e 's/\[\[.*\]\]/\n&\n/' |
	sed -e 's/\[\[\(.*\)\]\]/echo $\1/eg'
}

http_response_404(){
    header_begin 404
    {
        content_type "text/html"
    }
    header_end

    cat "$FILE_404"
}

http_response_dir(){
    if [ -f "$1"/"$FILE_INDEX" ]; then
        http_response_file "$1"/"$FILE_INDEX"
    else
        header_begin 200
        {
            content_type "text/html"
        }
        header_end

        LIST=$(ls -a "$1" |
                      sed "s|.*|<li><a href='${REQUEST_PATH%/}/&'>&</a></li>|") \
            TITLE="$1" \
            render_file "${DEFAULT_ROOT}"/dir.html
    fi
}

http_response_file(){
    header_begin 200
    {
        content_type_of "$1"
    }
    header_end

    cat "$1"
}

log(){
    echo "$@"
}

trap "echo exit;echo | nc localhost ${PORT};exit 1" HUP INT PIPE QUIT TERM
trap "echo exit;echo | nc localhost ${PORT}" EXIT

log "server started at ${PORT}"
while true; do
    coproc nc -l ${PORT}

    read -p METHOD REQUEST_PATH PROTOCOL
    while IFS=" " read -p k v; do
        if [ "$k" = "" ]; then
            break
        else
            k="$(echo "${k%:}" | tr a-z A-Z | tr - _)"
            v="${v%}"
            eval "$k"="\$v"
        fi
    done
    TIMESTAMP=$(LANG=C date)

    eval log ${LOG_FORMAT}
    FILE_REQUEST="${PROJECT_ROOT}${REQUEST_PATH}"
    if [ "$METHOD" = "GET" ];then
        if [ -e "$FILE_REQUEST" ];then
            if [ -d "$FILE_REQUEST" ];then
                http_response_dir "$FILE_REQUEST" >&p
            else
                http_response_file "$FILE_REQUEST" >&p
            fi
        else
            http_response_404 >&p
        fi
    fi
done
