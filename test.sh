﻿source ./functional.sh

assert() {
  if [ ! "$2" == "$3" ]
  then
    string.println "Assertion \"$1\" failed! $2 is not $3"
    exit 1
  fi
}

assert "println" "$(string.println "test")" "test"
assert "trim" "$(string.trim "  test ")" "test"
assert "split" "$(string.split "a+b+c+d" "+" | stream.mkString , [ ])" "[a,b,c,d]"
assert "replace" "$(string.replace "aaa" "a" "b")" "baa"
assert "replaceAll" "$(string.replaceAll "aaa" "a" "b")" "bbb"
assert "regexReplace" "$(string.regexReplace "asdfasdf" "s.f" "b")" "abasdf"
assert "regexReplaceAll" "$(string.regexReplaceAll "asdfasdf" "s.f" "b")" "abab"
assert "Chars" "$(Chars "test " | stream.mkString , [ ])" "[t,e,s,t, ]"
assert "List" "$(List "t" e s "t " | stream.mkString , [ ])" "[t,e,s,t ]"
assert "Option" "$(Option asdf | stream.getOrElse test)" "asdf"
array1[0]=t
array1[1]=e
array1[2]=s
array1[3]=t
array1[4]=" "
assert "Array" "$(Array array1 | stream.mkString , [ ])" "[t,e,s,t, ]"
assert "getOrElse" "$(Option | stream.getOrElse test)" "test"
assert "orElse" "$(Option asdf | (λ(){ string.println "test"; }; stream.orElse λ))" "asdf"
assert "orElse" "$(Option | (λ(){ string.println "test"; }; stream.orElse λ))" "test"
assert "map" "$(List foo "bar " test longword | (λ(){ Chars "$1" | stream.length; }; stream.map λ) | stream.mkString , [ ])" "[3,4,4,8]"
assert "filter" "$(List asdf abcde defg acorn | (λ(){ [[ "$1" == a* ]]; }; stream.filter λ) | stream.mkString , [ ])" "[asdf,abcde,acorn]"
assert "filterNot" "$(List asdf abcde defg acorn | (λ(){ [[ "$1" == a* ]]; }; stream.filterNot λ) | stream.mkString , [ ])" "[defg]"
assert "nonEmpty" "$(List asdf "" abcde " " defg acorn | stream.nonEmpty | stream.mkString , [ ])" "[asdf,abcde, ,defg,acorn]"
assert "length" "$(List asdf "" abcde " " defg acorn | stream.length)" "6"
assert "get" "$(List asdf "" abcde " " defg acorn | stream.get 4)" "defg"
assert "indexOf" "$(List asdf "" " abcde" " " defg acorn | stream.indexOf " abcde")" "2"
assert "find" "$(List asdf abcde defg acorn desk | (λ(){ [[ "$1" == d* ]]; }; stream.find λ) | stream.mkString , [ ])" "[defg]"
assert "zipWithIndex" "$(List asdf abcde defg acorn desk | stream.zipWithIndex | stream.mkString , [ ])" "[asdf 0,abcde 1,defg 2,acorn 3,desk 4]"
assert "zipWith" "$(List foo "bar " test longword | (λ(){ Chars "$1" | stream.length; }; stream.zipWith λ) | stream.mkString , [ ])" "[foo 3,bar  4,test 4,longword 8]"
assert "grouped" "$(List asdf abcde defg acorn desk | stream.grouped 3 | stream.mkString , [ ])" "[asdf abcde defg,acorn desk]"
assert "grouped" "$(List asdf abcde defg acorn desk test | stream.grouped 3 | stream.mkString , [ ])" "[asdf abcde defg,acorn desk test]"
assert "sorted" "$(List mnop asdf ijkl bcde fgh | stream.sorted | stream.mkString , [ ])" "[asdf,bcde,fgh,ijkl,mnop]"
assert "sortBy" "$(List test longword foo "bar " | (λ(){ Chars "$1" | stream.length; }; stream.sortBy λ) | stream.mkString , [ ])" "[foo,test,bar ,longword]"
assert "first" "$(Chars hello | stream.first | stream.mkString , [ ])" "[h]"
assert "head" "$(Chars hello | stream.head | stream.mkString , [ ])" "[h]"
assert "last" "$(Chars hello | stream.last | stream.mkString , [ ])" "[o]"
assert "tail" "$(Chars hello | stream.tail | stream.mkString , [ ])" "[e,l,l,o]"
assert "take" "$(Chars hello | stream.take 3 | stream.mkString , [ ])" "[h,e,l]"
assert "drop" "$(Chars hello | stream.drop 2 | stream.mkString , [ ])" "[l,l,o]"
assert "takeRight" "$(Chars hello | stream.takeRight 4 | stream.mkString , [ ])" "[e,l,l,o]"
assert "dropRight" "$(Chars hello | stream.dropRight 2 | stream.mkString , [ ])" "[h,e,l]"
assert "takeWhile" "$(Chars hello | (λ(){ [[ "$1" != "o" ]]; }; stream.takeWhile λ) | stream.mkString , [ ])" "[h,e,l,l]"
assert "dropWhile" "$(Chars hello | (λ(){ [[ "$1" != "l" ]]; }; stream.dropWhile λ) | stream.mkString , [ ])" "[l,l,o]"
assert "reverse" "$(Chars hello | stream.reverse | stream.mkString , [ ])" "[o,l,l,e,h]"
assert "repeat" "$(Chars hello | stream.repeat 2 | stream.mkString , [ ])" "[h,e,l,l,o,h,e,l,l,o]"
assert "repeat" "$(Chars hello | stream.repeat 0 | stream.mkString , [ ])" "[]"
assert "foldLeft" "$(Chars hello | (λ(){ string.println "$1$2"; }; stream.foldLeft "start" λ))" "starthello"
assert "intersperse" "$(Chars hello | stream.intersperse "-" | stream.mkString , [ ])" "[h,-,e,-,l,-,l,-,o]"
assert "prepend" "$(List hello | (λ(){ string.println "start"; }; stream.prepend λ) | stream.mkString , [ ])" "[start,hello]"
assert "append" "$(List hello | (λ(){ string.println "end"; }; stream.append λ) | stream.mkString , [ ])" "[hello,end]"
assert "mkString" "$(Chars hello | stream.mkString , [ ])" "[h,e,l,l,o]"
assert "toString" "$(Chars hello | stream.toString)" "hello"
assert "toList" "$(Chars hello | stream.toList)" "h e l l o"
assert "lines" "$(Chars hello | stream.lines)" "h"$'\n'"e"$'\n'"l"$'\n'"l"$'\n'"o"