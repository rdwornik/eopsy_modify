#!/bin/bash


#dirpattern="(\w*/)*\w*\S$"
sedpattern="s/\w+/\w+/(g|p|\d+|)"
name=`basename $0`

error_msg() 
{ 
        echo "$name: error: $1" 1>&2 
}


without_arg() 
{ 
        if [ ! -z "$1" ]
        then
                error_msg "no argument after -h"
                exit 1
        fi
        echo "evrthing fine" 
}

helpmsg(){
cat<<EOT 1>&2

Write a script modify with the following syntax:

  modify [-r] [-l|-u] <dir/file names...>
  modify [-r] <sed pattern> <dir/file names...>
  modify [-h]

  Proper sed pattern is "s/\w+/\w+/(g|p|\d+|)"
  
  modify_examples

EOT
}

modify(){
    local rec="$1"
    local flag="$2"
    local dir="$3"
    local filesinput="$4"

    messeges=`find $dir $rec -type f -name "$filesinput.*" -print -quit 2>&1 `
    if [[ -z "$messeges" ]];
    then
            error_msg "no such a file in directory"
    else
        find $dir $rec -type f -name "$filesinput.*" -print0 | while IFS= read -r -d '' file; 
        do
            dir=`dirname "$file"`
            filename=`basename "$file"`
            name="${filename%.*}"
            extension=$([[ "$filename" = *.* ]] && echo ".${filename##*.}" || echo '')
    

            case "$flag" in
            upper) 
            name="${name^^}"
            mv -v $file "$dir/$name$extension"
            ;;
            lower)
            name="${name,,}"
            mv -v "$file" "$dir/$name$extension"
            ;;
            *) 
            sed "$flag" "$file"
            ;;
        
            esac
            
        done
    fi
}


#recusrsion flag by defult set to null
rec="-maxdepth 1"
flag=""
dir=""
while getopts hru:l: opt
do
    case "$opt" in
        h) echo "Found the -h option" 
        helpmsg
        exit 1;;
        r)
        echo "Found the -r option" 
        rec="";;
        u) 
        echo "Found the -u option $OPTARG"
        dir=$OPTARG
        flag="upper"
        break;;
        l)
        option="-l" 
        echo "Found the -l option $OPTARG"
        dir=$OPTARG
        flag="lower"
        break;;
        *)
        #if wrong option is chosen exit
        echo "Unknown option"
        exit 1;;
    esac
done


#shift to parameters
shift $[ $OPTIND - 1 ]

#check if no flag was chosen  and does pattern much sed pattern

if [ -z "$flag" ] && [[ "$1" =~ $sedpattern ]]; then
    flag="$1"
    #shift to directory order
    shift
    dir="$1"
    if [ -z "$dir" ]; then
    error_msg "no directory to search in"
    exit 1
    else
    #shift to parameters after getting directiory path
    shift
    fi
fi

#check if no flags chosen and sed patern is incroect
if [ -z "$flag" ]; then
    if [ -z "$1" ]; then
    error_msg "no arguments inserted"
    exit 1
    fi
    if [[ ! "$1" =~ $sedpattern ]]; then
    error_msg "no such a sed pattern"
    exit 1
    fi
fi

#arguemnts shifted to parameters

if [ -z "$1" ];then
    error_msg "no file names were given"
    exit 1
fi

#if all conditon where met we can finally proced
count=1
for param in "$@"
do
echo "Parameter $count: $param"
count=$[ $count + 1 ]
modify "$rec" "$flag" "$dir" "$param"
done

