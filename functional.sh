newline=$'\n'

print() {
  printf '%s' "$1"
}

println() {
  printf '%s\n' "$1"
}

Chars() {
  local _string="$1"

  print "$_string" | sed -e 's/\(.\)/\1\n/g'
}

List() {
  for _elem in "$@"
  do
    println "$_elem"
  done
}

Option() {
  local _elem="$@"

  if ! [ -z "$_elem" ]
  then
    println "$_elem"
  fi
}

Variable() {
  local _variable="$1"

  if ! [ -z ${!_variable+x} ]
  then
    println "${!_variable}"
  fi
}

Array() {
  local _arr="$1"
  local _off=$(Option "$2" | getOrElse 0)
  local _len=$(Option "$3" | (λ(){ eval println $\{#$_arr[@]\}; }; orElse λ))

  for _i in $(seq $_off $(( $_off + $_len - 1 )))
  do
    local _elem=$_arr[$_i]
    println "${!_elem}"
  done
}

isEmpty() {
  local _empty=true

  while read -r
  do
    println "$REPLY"
    _empty=false
  done

  $_empty
}

getOrElse() {
  local _elem="$1"

  if isEmpty
  then
    println "$_elem"
  fi
}

orElse() {
  local _func="$1"

  if isEmpty
  then
    (eval "$_func")
  fi
}

map() {
  local _func="$1"

  while read -r
  do
    (eval "$_func \"$REPLY\"")
  done
}

filter() {
  local _func="$1"

  while read -r
  do
    if $(eval "$_func \"$REPLY\"")
    then
      println "$REPLY"
    fi
  done
}

filterNot() {
  local _func="$1"

  filter "! $_func"
}

nonEmpty() {
  while read -r
  do
    if ! [ -z "$REPLY" ]
    then
      println "$REPLY"
    fi
  done
}

length() {
  local _length=0

  while read -r
  do
    _length=$(( $_length + 1 ))
  done

  println $_length
}

get() {
  local _index="$1"

  local _i=0
  while read -r
  do
    if (( $_i == $_index )); then println "$REPLY"; fi
    _i=$(( $_i + 1 ))
  done
}

indexOf() {
  local _elem="$1"

  local _i=0
  while read -r
  do
    if [ "$REPLY" == "$_elem" ]; then println $_i; fi
    _i=$(( $_i + 1 ))
  done
}

zipWithIndex() {
  local _i=0
  while read -r
  do
    println "$REPLY $_i"
    _i=$(( $_i + 1 ))
  done
}

zipWith() {
  local _func="$1"

  while read -r
  do
    local _elem=$REPLY
    eval "$_func \"$_elem\"" |
      (λ(){ println "$_elem $1"; }; map λ)
  done
}

grouped() {
  local _size=$(Option "$1" | getOrElse 2)

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

  while read -r
  do
    println "${REPLY//$_sep/$newline}"
  done
}

sorted() {
  sort "$@"
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
  local _func2=$(List "$@" | last)
  local _options=$(List "$@" | dropRight 1 | toList)

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
      local _by=$(eval "$_func2 \"$_e\"")
      println "$_by $_i"
    }; map _lambda) |
    sorted -k1,1 $_options |
    (λ(){
      local _i=$(List $1 | last)
      println "${_buffer[$_i]}"
    }; map λ)
}

takeLeft() {
  local _take=$(Option "$1" | getOrElse 1)

  while read -r
  do
    if (( $_take > 0 ))
    then
      println "$REPLY"
    else
      break
    fi
    _take=$(( $_take - 1 ))
  done
}

dropLeft() {
  local _drop=$(Option "$1" | getOrElse 1)

  while read -r
  do
    if (( $_drop > 0 ))
    then
      _drop=$(( $_drop - 1 ))
    else
      println "$REPLY"
    fi
  done
}

takeRight() {
  local _take=$(Option "$1" | getOrElse 1)

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
      println "${_buffer[$_pointer]}"
    done
  fi
}

dropRight() {
  local _drop=$(Option "$1" | getOrElse 1)

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
        println "${_buffer[$_pointer]}"
      fi
      _buffer[$_pointer]="$REPLY"
      if (( $_length < $_drop )); then _length=$(( $_length + 1 )); fi
    done
  fi
}

takeWhile() {
  local _func="$1"

  while read -r
  do
    if $(eval "$_func \"$REPLY\"")
    then
      println "$REPLY"
    else
      break
    fi
  done
}

dropWhile() {
  local _func="$1"

  local _take=false
  while read -r
  do
    if $_take || ! $(eval "$_func \"$REPLY\"")
    then
      _take=true
      println "$REPLY"
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
    println "${_buffer[$_length]}"
  done
}

repeat() {
  local times="$1"

  local _buffer[0]=""
  local _length=0
  while read -r
  do
    _buffer[$_length]="$REPLY"
    _length=$(( $_length + 1 ))
  done

  for _i in $(seq 1 $times)
  do
    local _index=0
    while (( _index < _length ))
    do
      println "${_buffer[$_index]}"
      _index=$(( $_index + 1 ))
    done
  done
}

foldLeft() {
  local _acc="$1"
  local _func="$2"

  while read -r
  do
    _acc=$(eval "$_func \"$_acc\" \"$REPLY\"")
  done

  println "$_acc"
}

intersperse() {
  local _elem="$1"

  local _first=true
  while read -r
  do
    if $_first
    then
      _first=false
    else
      println "$_elem"
    fi
    println "$REPLY"
  done
}

prepend() {
  local _func="$1"

  eval "$_func" | while read -r
  do
    println "$REPLY"
  done

  while read -r
  do
    println "$REPLY"
  done
}

append() {
  local _func="$1"

  while read -r
  do
    println "$REPLY"
  done

  eval "$_func" | while read -r
  do
    println "$REPLY"
  done
}

mkString() {
  local _sep="$1"

  intersperse "$_sep" | (λ(){ println "$1$2"; }; foldLeft "" λ)
}

toString() {
  mkString ""
}

toList() {
  mkString " "
}