#!/usr/bin/env bash

set -o pipefail

# class string

#deprecated
string.print() {
  printf '%s' "$1"
}

print() {
  printf '%s' "$1"
}

#deprecated
string.println() {
  printf '%s\n' "$1"
}

println() {
  printf '%s\n' "$1"
}

string.escapeNewline() {
  local _string="$1"
  local _quoted="${_string//\\/\\\\}"

  println "${_quoted//$'\n'/\\n}"
}

string.unescapeNewline() {
  local _string="$1"

  print "$_string" | perl -C -ple 's/(?<!\\)(\\\\)*\\n/\1\n/g; s/\\\\/\\/g'
}

string.quote() {
  local _first=true
  for _string in "$@"
  do
    if $_first
    then
      _first=false
    else
      print ' '
    fi
    print "'$(string.replaceAll "$_string" "'" "'\"'\"'")'"
  done
  println ''
}

string.trim() {
  local _string="$1"

  string.regexReplaceAll "$_string" '^ *| *$' ''
}

string.split() {
  local _string="$1"
  local _sep="$2"

  string.replaceAll "$_string" "$_sep" $'\n'
}

string.replace() {
  local _string="$1"
  local _pattern="$2"
  local _substitution="$3"

  println "${_string/"$_pattern"/$_substitution}"
}

string.replaceAll() {
  local _string="$1"
  local _pattern="$2"
  local _substitution="$3"

  println "${_string//"$_pattern"/$_substitution}"
}

string.regexReplace() {
  local _string="$1"
  local -x _regex="$2"
  local -x _substitution="$3"

  print "$_string" | perl -C -ple "s/\$ENV{'_regex'}/\$ENV{'_substitution'}/"
}

string.regexReplaceAll() {
  local _string="$1"
  local -x _regex="$2"
  local -x _substitution="$3"

  print "$_string" | perl -C -ple "s/\$ENV{'_regex'}/\$ENV{'_substitution'}/g"
}

string.matches() {

}

# object stream

Range() {
  local _start="$1"
  local _end="$2"

  seq "$_start" "$(($_end - 1))"
}

InclusiveRange() {
  local _start="$1"
  local _end="$2"

  seq "$_start" "$_end"
}

Chars() {
  local _string="$1"

  string.regexReplaceAll "$_string" '(.)' '\1\n' | stream.init
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

File() {
  local _path="$1"

  cat "$_path"
}

Variable() {
  local _variable="$1"

  if ! [ -z ${!_variable+x} ]
  then
    println "${!_variable}"
  fi
}

Array() {
  local _newline=false
  if [ "$1" == "-n" ]
  then
    _newline=true
    shift
  fi

  local _arr="$1"
  local _off=$(Option "$2" | stream.getOrElse 0)
  local _len=$(Option "$3" | (stream.orElse <(eval println $\{#$_arr[@]\})))

  for _i in $(Range $_off $(( $_off + $_len )))
  do
    local _elem=$_arr[$_i]
    if $_newline
    then
      string.escapeNewline "${!_elem}"
    else
      println "${!_elem}"
    fi
  done
}

# class stream

stream.isEmpty() {
  local _empty=true
  while IFS= read -r
  do
    println "$REPLY"
    _empty=false
  done

  $_empty
}

stream.getOrElse() {
  local _elem="$1"

  if stream.isEmpty
  then
    println "$_elem"
  fi
}

stream.orElse() {
  local _stream="$1"

  if stream.isEmpty
  then
    while IFS= read -r
    do
      println "$REPLY"
    done <"$_stream"
  fi
}

stream.if() {
  local _bool="$@"

  if $(eval "$_bool")
  then
    stream.identity
  else
    stream.ignore
  fi
}

stream.identity() {
  while IFS= read -r
  do
    println "$REPLY"
  done
}

stream.ignore() {
  while IFS= read -r
  do
    :
  done
}

stream.map() {
  local _func="$1"
  shift
  local _args="$(string.quote "$@")"

  while IFS= read -r
  do
    (eval "$_func $(string.quote "$REPLY") $_args")
  done
}

stream.mapN() {
  local _length="$1"
  local _func="$2"
  shift 2
  local _args="$(string.quote "$@")"

  local _i=0
  local _args1=""
  while IFS= read -r
  do
    _args1="$_args1 $(string.quote "$REPLY")"
    _i=$(( $_i + 1 ))
    if (( $_i >= $_length ))
    then
      _i=0
      (eval "$_func$_args1 $_args")
      _args1=""
    fi
  done
}

stream.foreach() {
  local _func="$1"
  shift
  local _args="$(string.quote "$@")"

  while IFS= read -r
  do
    eval "$_func $(string.quote "$REPLY") $_args" |
      stream.ignore
  done
}

stream.filter() {
  local _func="$1"
  shift
  local _args="$(string.quote "$@")"

  while IFS= read -r
  do
    if $(eval "$_func $(string.quote "$REPLY") $_args")
    then
      println "$REPLY"
    fi
  done
}

stream.filterNot() {
  local _func="$1"
  shift
  local _args="$(string.quote "$@")"

  stream.filter "! $_func" $_args
}

stream.nonEmpty() {
  while IFS= read -r
  do
    if ! [ -z "$REPLY" ]
    then
      println "$REPLY"
    fi
  done
}

stream.length() {
  local _length=0

  while IFS= read -r
  do
    _length=$(( $_length + 1 ))
  done

  println $_length
}

stream.get() {
  local _index="$1"

  local _i=0
  while IFS= read -r
  do
    if (( $_i == $_index ))
    then
      println "$REPLY"
      break
    fi
    _i=$(( $_i + 1 ))
  done
}

stream.indexOf() {
  local _elem="$1"

  local _i=0
  while IFS= read -r
  do
    if [ "$REPLY" == "$_elem" ]
    then
      println $_i
      return
    fi
    _i=$(( $_i + 1 ))
  done

  println -1
}

stream.find() {
  local _func="$1"
  shift
  local _args="$(string.quote "$@")"

  while IFS= read -r
  do
    if $(eval "$_func $(string.quote "$REPLY") $_args")
    then
      println "$REPLY"
      break
    fi
  done
}

stream.zipWithIndex() {
  local _i=0
  while IFS= read -r
  do
    println "$REPLY $_i"
    _i=$(( $_i + 1 ))
  done
}

stream.zipWith() {
  local _func="$1"
  shift
  local _args="$(string.quote "$@")"

  while IFS= read -r
  do
    _elem="$REPLY"
    eval "$_func $(string.quote "$REPLY") $_args" |
      (F(){ println "$_elem $1"; }; stream.map F)
  done
}

stream.grouped() {
  local _size=$(Option "$1" | stream.getOrElse 2)

  local _buffer[0]=""
  local _length=0
  while IFS= read -r
  do
    _buffer[$_length]="$REPLY"
    _length=$(( $_length + 1 ))
    if (( $_length >= $_size ))
    then
      Array _buffer 0 _length | stream.mkString " "
      _length=0
    fi
  done

  if (( $_length > 0 ))
  then
    Array _buffer 0 _length | stream.mkString " "
  fi
}

stream.sorted() {
  sort "$@"
}

stream.sortBy() {
  local _func2=$(List "$@" | stream.last)
  local _options=$(List "$@" | stream.dropRight 1 | stream.toList)

  local _buffer[0]=""
  local _length=0
  while IFS= read -r
  do
    _buffer[$_length]="$REPLY"
    _length=$(( $_length + 1 ))
  done

  Array _buffer 0 $_length |
    stream.zipWithIndex |
    (_lambda(){
      local _i=$(List $1 | stream.last)
      local _e=$(Chars "$1" | stream.dropRight $(( $(Chars "$_i" | stream.length) + 1 )) | stream.mkString | stream.map string.quote)
      local _by=$(eval "$_func2 $_e")
      println "$_by $_i"
    }; stream.map _lambda) |
    stream.sorted -k1,1 $_options |
    (F(){
      local _i=$(List $1 | stream.last)
      println "${_buffer[$_i]}"
    }; stream.map F)
}

stream.startsWith() {
  local _elem="$1"

  [ "$(stream.first)" == "$_elem" ]
}

stream.endsWith() {
  local _elem="$1"

  [ "$(stream.last)" == "$_elem" ]
}

stream.contains() {
  local _elem="$1"

  [ "$(stream.indexOf "$_elem")" != "-1" ]
}

stream.first() {
  stream.take 1
}

stream.head() {
  stream.take 1
}

stream.last() {
  stream.takeRight 1
}

stream.init() {
  local _first=true
  local _last=""
  while IFS= read -r
  do
    if $_first
    then
      _first=false
    else
      println "$_last"
    fi
    _last="$REPLY"
  done
}

stream.tail() {
  stream.drop 1
}

stream.take() {
  local _take=$(Option "$1" | stream.getOrElse 1)

  while IFS= read -r
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

stream.drop() {
  local _drop=$(Option "$1" | stream.getOrElse 1)

  while IFS= read -r
  do
    if (( $_drop > 0 ))
    then
      _drop=$(( $_drop - 1 ))
    else
      println "$REPLY"
    fi
  done
}

stream.takeRight() {
  local _take=$(Option "$1" | stream.getOrElse 1)

  if (( $_take > 0 ))
  then
    local _buffer[0]=""
    local _pointer=-1
    local _length=0
    while IFS= read -r
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

stream.dropRight() {
  local _drop=$(Option "$1" | stream.getOrElse 1)

  if (( $_drop <= 0 ))
  then
    cat
  else
    local _buffer[0]=""
    local _pointer=-1
    local _length=0
    while IFS= read -r
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

stream.takeWhile() {
  local _func="$1"
  shift
  local _args="$(string.quote "$@")"

  while IFS= read -r
  do
    if $(eval "$_func $(string.quote "$REPLY") $_args")
    then
      println "$REPLY"
    else
      break
    fi
  done
}

stream.dropWhile() {
  local _func="$1"
  shift
  local _args="$(string.quote "$@")"

  local _take=false
  while IFS= read -r
  do
    if $_take || ! $(eval "$_func $(string.quote "$REPLY") $_args")
    then
      _take=true
      println "$REPLY"
    fi
  done
}

stream.reverse() {
  local _buffer[0]=""
  local _length=0
  while IFS= read -r
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

stream.repeat() {
  local times="$1"

  local _buffer[0]=""
  local _length=0
  while IFS= read -r
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

stream.foldLeft() {
  local _acc="$1"
  local _func="$2"
  shift 2
  local _args="$(string.quote "$@")"

  while IFS= read -r
  do
    _acc=$(eval "$_func $(string.quote "$_acc") $(string.quote "$REPLY") $_args")
  done

  println "$_acc"
}

stream.intersperse() {
  local _elem="$1"

  local _first=true
  while IFS= read -r
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

stream.prepend() {
  for _elem in "$@"
  do
    println "$_elem"
  done

  while IFS= read -r
  do
    println "$REPLY"
  done
}

stream.append() {
  while IFS= read -r
  do
    println "$REPLY"
  done

  for _elem in "$@"
  do
    println "$_elem"
  done
}

stream.concat() {
  stream.appendAll "$@"
}

stream.prependAll() {
  local _stream="$1"

  while IFS= read -r
  do
    println "$REPLY"
  done <"$_stream"

  while IFS= read -r
  do
    println "$REPLY"
  done
}

stream.appendAll() {
  local _stream="$1"

  while IFS= read -r
  do
    println "$REPLY"
  done

  while IFS= read -r
  do
    println "$REPLY"
  done <"$_stream"
}

stream.lines() {
  while IFS= read -r
  do
    println "$REPLY"
  done
}

stream.mkString() {
  local _sep="$1"
  local _start="$2"
  local _end="$3"

  local _string="$_start"
  local _first=true
  while IFS= read -r
  do
    if $_first
    then
      _first=false
      _string="$_string$REPLY"
    else
      _string="$_string$_sep$REPLY"
    fi
  done

  println "$_string$_end"
}

stream.toString() {
  stream.mkString ""
}

stream.toList() {
  stream.mkString " "
}

stream.toLines() {
  stream.mkString $'\n'
}
