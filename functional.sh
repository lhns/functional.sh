Chars() {
  local _string="$1"
  shift

  printf "$_string" | sed -e 's/\(.\)/\1\n/g'
}

List() {
  for _elem in "$@"
  do
    echo "$_elem"
  done
}

Option() {
  local _elem="$@"
  if ! [ -z "$_elem" ]
  then
    echo "$_elem"
  fi
}

Variable() {
  local _variable="$1"
  if ! [ -z ${!_variable+x} ]
  then
    echo "${!_variable}"
  fi
}

Array() {
  local _arr="$1"
  local _off=$(Option "$2" | getOrElse 0)
  local _len=$(Option "$3" | (λ(){ eval echo $\{#$_arr[@]\}; }; orElse λ))
  shift

  for _i in $(seq $_off $(( $_off + $_len - 1 )))
  do
    local _elem=$_arr[$_i]
    echo "${!_elem}"
  done
}

newline=$'\n'

isEmpty() {
  local _empty=true

  while read -r
  do
    echo "$REPLY"
    _empty=false
  done

  $_empty
}

getOrElse() {
  local _elem="$1"
  shift

  if isEmpty
  then
    echo "$_elem"
  fi
}

orElse() {
  local _func="$1"
  shift

  if isEmpty
  then
    eval "$_func $@" | while read -r
    do
      echo "$REPLY"
    done
  fi
}

map() {
  local _func="$1"
  shift

  while read -r
  do
    eval "$_func \"$REPLY\" $@"
  done
}

filter() {
  local _func="$1"
  shift

  while read -r
  do
    if $(eval "$_func \"$REPLY\" $@")
    then
      echo "$REPLY"
    fi
  done
}

filterNot() {
  local _func="$1"
  shift

  filter "! $_func"
}

nonEmpty() {
  while read -r
  do
    if ! [ -z "$REPLY" ]
    then
      echo "$REPLY"
    fi
  done
}

length() {
  local _length=0

  while read -r
  do
    _length=$(( $_length + 1 ))
  done

  echo $_length
}

get() {
  local _index="$1"
  shift

  local _i=0
  while read -r
  do
    if (( $_i == $_index )); then echo "$REPLY"; fi
    _i=$(( $_i + 1 ))
  done
}

indexOf() {
  local _elem="$1"
  shift

  local _i=0
  while read -r
  do
    if [ "$REPLY" == "$_elem" ]; then echo $_i; fi
    _i=$(( $_i + 1 ))
  done
}

zipWithIndex() {
  local _i=0
  while read -r
  do
    echo "$REPLY $_i"
    _i=$(( $_i + 1 ))
  done
}

zipWith() {
  local _func="$1"
  shift

  while read -r
  do
    _elem=$REPLY
    eval "$_func \"$_elem\" $@" |
      (λ(){ echo "$_elem $1"; }; map λ)
  done
}

grouped() {
  local _size=$(Option "$1" | getOrElse 2)
  shift

  local _buffer[0]=""
  local _length=0
  while read -r
  do
    _buffer[$_length]="$REPLY"
    _length=$(( $_length + 1 ))
    if (( $_length >= $_size ))
    then
      Array _buffer 0 _length | mkString " "
      _length=0
    fi
  done
}

split() {
  local _sep="$1"
  shift

  while read -r
  do
    echo "${REPLY//$_sep/$newline}"
  done
}

sorted() {
  sort
}

first() {
  takeLeft 1
}

head() {
  takeLeft 1
}

last() {
  takeRight 1
}

tail() {
  dropLeft 1
}

sortBy() {
  local _func2="$1"
  shift

  local _buffer[0]=""
  local _length=0
  while read -r
  do
    _buffer[$_length]="$REPLY"
    _length=$(( $_length + 1 ))
  done

  Array _buffer 0 $_length |
    zipWithIndex |
    (_lambda(){
      local _i=$(List $1 | last)
      local _e=$(Chars "$1" | dropRight $(( $(Chars "$_i" | length) + 1 )) | mkString)
      local _by=$(eval "$_func2 \"$_e\" $@")
      echo "$_by $_i"
    }; map _lambda) |
    sorted |
    (λ(){
      local _i=$(List $1 | last)
      echo "${_buffer[$_i]}"
    }; map λ)
}

takeLeft() {
  local _take=$(Option "$1" | getOrElse 1)
  shift

  while read -r
  do
    if (( $_take > 0 ))
    then
      echo "$REPLY"
    else
      break
    fi
    _take=$(( $_take - 1 ))
  done
}

dropLeft() {
  local _drop=$(Option "$1" | getOrElse 1)
  shift

  while read -r
  do
    if (( $_drop > 0 ))
    then
      _drop=$(( $_drop - 1 ))
    else
      echo "$REPLY"
    fi
  done
}

takeRight() {
  local _take=$(Option "$1" | getOrElse 1)
  shift

  if (( $_take > 0 ))
  then
    local _buffer[0]=""
    local _pointer=-1
    local _length=0
    while read -r
    do
      _pointer=$(( ($_pointer + 1) % $_take ))
      _buffer[$_pointer]="$REPLY"
      if (( $_length < $_take )); then _length=$(( $_length + 1 )); fi
    done

    for i in $(seq 1 $_length)
    do
      _pointer=$(( ($_pointer + 1) % $_length ))
      echo "${_buffer[$_pointer]}"
    done
  fi
}

dropRight() {
  local _drop=$(Option "$1" | getOrElse 1)
  shift

  if (( $_drop <= 0 ))
  then
    cat
  else
    local _buffer[0]=""
    local _pointer=-1
    local _length=0
    while read -r
    do
      _pointer=$(( ($_pointer + 1) % $_drop ))
      if (( $_pointer < $_length ))
      then
        echo ${_buffer[$_pointer]}
      fi
      _buffer[$_pointer]="$REPLY"
      if (( $_length < $_drop )); then _length=$(( $_length + 1 )); fi
    done
  fi
}

takeWhile() {
  local _func="$1"
  shift

  while read -r
  do
    if $(eval "$_func \"$REPLY\" $@")
    then
      echo "$REPLY"
    else
      break
    fi
  done
}

dropWhile() {
  local _func="$1"
  local _take=false
  shift

  while read -r
  do
    if $_take || ! $(eval "$_func \"$REPLY\" $@")
    then
      _take=true
      echo "$REPLY"
    fi
  done
}

reverse() {
  local _buffer[0]=""
  local _length=0

  while read -r
  do
    _buffer[$_length]="$REPLY"
    _length=$(( $_length + 1 ))
  done

  while (( _length > 0 ))
  do
    _length=$(( $_length - 1 ))
    echo "${_buffer[$_length]}"
  done
}

foldLeft() {
  local _acc="$1"
  local _func="$2"
  shift 2

  while read -r
  do
    _acc=$(eval "$_func \"$_acc\" \"$REPLY\" $@")
  done

  echo "$_acc"
}

intersperse() {
  local _elem="$1"
  local _first=true
  shift

  while read -r
  do
    if $_first
    then
      _first=false
    else
      echo "$_elem"
    fi
    echo "$REPLY"
  done
}

prepend() {
  local _func="$1"
  shift

  eval "$_func $@" | while read -r
  do
    echo "$REPLY"
  done

  while read -r
  do
    echo "$REPLY"
  done
}

append() {
  local _func="$1"
  shift

  while read -r
  do
    echo "$REPLY"
  done

  eval "$_func $@" | while read -r
  do
    echo "$REPLY"
  done
}

mkString() {
  local _sep="$1"
  shift

  intersperse "$_sep" | (λ(){ echo "$1$2"; }; foldLeft "" λ)
}

toString() {
  mkString ""
}

toList() {
  mkString " "
}