map() {
  local f="$1"
  shift

  while read -r
  do
    eval "$f \"$REPLY\" $@"
  done
}

filter() {
  local f="$1"
  shift

  while read -r
  do
    if $(eval "$f \"$REPLY\" $@")
    then
      echo "$REPLY"
    fi
  done
}

filterNot() {
  local f="$1"
  shift

  filter "! $f"
}

#alsoTo

length() {
  local length=0

  while read -r
  do
    length=$(( $length+1 ))
  done

  echo $length
}

get() {
  local index="$1"
  shift

  local i=0
  while read -r
  do
    if (( $i == $index )); then echo "$REPLY"; fi
    i=$(( $i+1 ))
  done
}

indexOf() {
  local e="$1"
  shift

  local i=0
  while read -r
  do
    if [ "$REPLY" == "$e" ]; then echo $i; fi
    i=$(( $i+1 ))
  done
}

zipWithIndex() {
  local i=0
  while read -r
  do
    echo "$REPLY $i"
    i=$(( i + 1 ))
  done
}

grouped() {
  local size=$(Option "$1" | getOrElse 2)
  shift

  local buffer[0]=""
  local length=0
  while read -r
  do
    buffer[$length]="$REPLY"
    length=$(( $length + 1 ))
    if (( $length >= $size ))
    then
      Array buffer 0 length | mkString " "
      length=0
    fi
  done
}

sorted() {
  sort
}

first() {
  takeLeft
}

last() {
  takeRight
}

tail() {
  dropLeft
}

sortBy() {(
  local f="$1"
  shift

  local buffer[0]=""
  local length=0

  while read -r
  do
    buffer[$length]="$REPLY"
    length=$(( $length + 1 ))
  done

  Array buffer 0 $length |
    zipWithIndex |
    (λ1(){
      local i=$(List $1 | last)
      local e=$(String "$1" | dropRight $(( $(String "$i" | length) + 1 )) | mkString)
      echo 1
      eval "$f"
      echo 2
      echo "$r $i"
    }; map λ1)
    #sorted
    #(λ(){
    #  local i=$(List $1 | last)
    #  echo "${buffer[$i]}"
    #}; map λ)

  #while (( length > 0 ))
  #do
  #  length=$(( $length - 1 ))
  #  echo "${buffer[$length]}"
  #done
)}

takeWhile() {
  local f="$1"
  shift

  while read -r
  do
    if $(eval "$f \"$REPLY\" $@")
    then
      echo "$REPLY"
    else
      break
    fi
  done
}

dropWhile() {
  local f="$1"
  local take=false
  shift

  while read -r
  do
    if $take || ! $(eval "$f \"$REPLY\" $@")
    then
      take=true
      echo "$REPLY"
    fi
  done
}

takeLeft() {
  local take=$(Option "$1" | getOrElse 1)
  shift

  while read -r
  do
    if (( $take > 0 ))
    then
      echo "$REPLY"
    else
      break
    fi
    take=$(( $take - 1 ))
  done
}

dropLeft() {
  local drop=$(Option "$1" | getOrElse 1)
  shift

  while read -r
  do
    if (( $drop > 0 ))
    then
      drop=$(( $drop - 1 ))
    else
      echo "$REPLY"
    fi
  done
}

takeRight() {
  local take=$(Option "$1" | getOrElse 1)
  shift

  if (( $take > 0 ))
  then
    local buffer[0]=""
    local pointer=-1
    local length=0
    while read -r
    do
      pointer=$(( ($pointer + 1) % $take ))
      buffer[$pointer]="$REPLY"
      if (( $length < $take )); then length=$(( $length + 1 )); fi
    done

    for i in $(seq 1 $length)
    do
      pointer=$(( ($pointer + 1) % $length ))
      echo "${buffer[$pointer]}"
    done
  fi
}

dropRight() {
  local drop=$(Option "$1" | getOrElse 1)
  shift

  if (( $drop <= 0 ))
  then
    cat
  else
    local buffer[0]=""
    local pointer=-1
    local length=0
    while read -r
    do
      pointer=$(( ($pointer + 1) % $drop ))
      if (( $pointer < $length ))
      then
        echo ${buffer[$pointer]}
      fi
      buffer[$pointer]="$REPLY"
      if (( $length < $drop )); then length=$(( $length + 1 )); fi
    done
  fi
}

reverse() {
  local buffer[0]=""
  local length=0

  while read -r
  do
    buffer[$length]="$REPLY"
    length=$(( $length + 1 ))
  done

  while (( length > 0 ))
  do
    length=$(( $length - 1 ))
    echo "${buffer[$length]}"
  done
}

foldLeft() {
  local acc="$1"
  local f="$2"
  shift 2

  while read -r
  do
    acc=$(eval "$f \"$acc\" \"$REPLY\" $@")
  done

  echo "$acc"
}

Array() {
  local arr="$1"
  local off=$(Option "$2" | getOrElse 0)
  local len=$(Option "$3" | (λ2(){ eval echo $\{#$arr[@]\}; }; orElse λ2))
  shift

  for i in $(seq $off $(( $off + $len - 1 )))
  do
    local elem=$arr[$i]
    echo "${!elem}"
  done
}

String() {
  local str="$1"
  shift

  printf "$str" | sed -e 's/\(.\)/\1\n/g'
}

List() {
  for e in "$@"
  do
    echo "$e"
  done
}

Defined() {
  local var="$1"
  if ! [ -z ${!var+x} ]
  then
    echo "${!var}"
  fi
}

Option() {
  local e="$1"
  if ! [ -z "$e" ]
  then
    echo "$e"
  fi
}

isEmpty() {
  local empty=true

  while read -r
  do
    echo "$REPLY"
    empty=false
  done

  $empty
}

getOrElse() {
  local e="$1"
  shift

  if isEmpty
  then
    echo "$e"
  fi
}

orElse() {
  local f="$1"
  shift

  if isEmpty
  then
    eval "$f $@" | while read -r
    do
      echo "$REPLY"
    done
  fi
}

intersperse() {
  local e="$1"
  local first=true
  shift

  while read -r
  do
    if $first
    then
      first=false
    else
      echo "$e"
    fi
    echo "$REPLY"
  done
}

mkString() {
  local sep="$1"
  shift

  intersperse "$sep" | (λ3(){ echo "$1$2"; }; foldLeft "" λ3)
}

prepend() {
  local f="$1"
  shift

  eval "$f $@" | while read -r
  do
    echo "$REPLY"
  done

  while read -r
  do
    echo "$REPLY"
  done
}

append() {
  local f="$1"
  shift

  while read -r
  do
    echo "$REPLY"
  done

  eval "$f $@" | while read -r
  do
    echo "$REPLY"
  done
}

List ab abc bcd bcde bcdef zyx |
  #(λ(){ echo "Lambda sees $1 and $2 and $3"; }; map λ a b) |
  #(λ(){ echo "Lambda sees $1 and $2 and $3"; }; map λ) |
  (λ(){ [[ "$1" == *b* ]]; }; filter λ) |
  (λ(){ [[ "$1" == a* ]]; }; dropWhile λ) |
  (λ(){ echo "$1 $2"; }; foldLeft "a " λ) |
  cat

#bvar=test
echo a
Option bvar | (λ(){ echo "abc"; echo "def"; }; orElse λ) | getOrElse other | cat
echo c
echo "---"
List a bcd ef | intersperse "=" | (λ(){ List end; }; prepend λ) | mkString " "
echo "---"
String "asdf" | reverse | mkString
echo "---"
a[0]=a2
a[1]=s1
a[2]=d6
a[3]=f3
Array a | (λ(){ echo "test"; }; sortBy λ)
