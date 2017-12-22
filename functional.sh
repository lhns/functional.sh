map() {
  local f="$1"
  shift

  while read -r
  do
    eval "$f" "$REPLY" $@
  done
}

filter() {
  local f="$1"
  shift

  while read -r
  do
    if "$f" "$REPLY" $@
    then
      echo "$REPLY"
    fi
  done
}

filterNot() {
  local f="$1"
  shift

  while read -r
  do
    if ! "$f" "$REPLY" $@
    then
      echo "$REPLY"
    fi
  done
}

takeWhile() {
  local f="$1"
  shift

  while read -r
  do
    if "$f" "$REPLY" $@
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
    if $take || ! "$f" "$REPLY" $@
    then
      take=true
      echo "$REPLY"
    fi
  done
}

foldLeft() {
  local acc="$1"
  local f="$2"
  shift 2

  while read -r
  do
    acc=$("$f" "$acc" "$REPLY" $@)
  done

  echo "$acc"
}

List() {
  for e in "$@"
  do
    echo "$e"
  done
}

Option() {
  local var="$1"
  if ! [ -z ${!var+x} ]
  then
    echo "${!var}"
  fi
}

getOrElse() {
  local e="$1"
  local empty=true

  while read -r
  do
    echo "$REPLY"
    empty=false
  done

  if $empty
  then
    echo "$e"
  fi
}

orElse() {
  local f="$1"
  local empty=true
  shift

  while read -r
  do
    echo "$REPLY"
    empty=false
  done

  if $empty
  then
    "$f" $@ | while read -r
    do
      echo "$REPLY"
    done
  fi
}

printf "ab\nabc\nbcd\nbcde\nbcdef\nzyx\n" |
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
