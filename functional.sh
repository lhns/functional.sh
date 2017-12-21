map() { local f="$1"; shift; while read -r; do "$f" "$REPLY" $@; done; }

filter() { local f="$1"; shift; while read -r; do if "$f" "$REPLY" $@; then echo "$REPLY"; fi; done; }

filterNot() { local f="$1"; shift; while read -r; do if ! "$f" "$REPLY" $@; then echo "$REPLY"; fi; done; }

printf "ab\nb\nbca\n" |
  (λ(){ [[ "$1" == b* ]]; }; filterNot λ) |
  (λ(){ echo "Lambda sees $1 and $2 and $3"; }; map λ a b) |
  (λ(){ echo "Lambda sees $1 and $2 and $3"; }; map λ) |
  cat
