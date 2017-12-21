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
  shift
  local take=false

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
  shift
  local f="$1"
  shift

  while read -r
  do
    echo $REPLY
    acc=$(("$f" "$acc" "$REPLY" $@))
    echo $acc
    echo "."
  done

  echo $acc
}

printf "ab\nabc\nbcd\nbcde\nzyx\n" |
  #(λ(){ echo "Lambda sees $1 and $2 and $3"; }; map λ a b) |
  #(λ(){ echo "Lambda sees $1 and $2 and $3"; }; map λ) |
  (λ(){ [[ "$1" == *b* ]]; }; filter λ) |
  (λ(){ [[ "$1" == a* ]]; }; dropWhile λ) |
  (λ(){ echo "$1 $2"; }; foldLeft "a " λ) |
  cat
