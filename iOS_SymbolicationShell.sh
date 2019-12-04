#!/bin/bash

#useage1 sh iOS_SymbolicationShell.sh myApp（myApp means dsym preshort name）
#useage2 sh iOS_SymbolicationShell.sh myApp arm64
#put this file with the same location of dsym file
#Note: crash report should be named with myApp.txt or **.crash
#@author mutianyou1@126.com

function exit_shell() {
    echo "none valida architecture"
    exit 0
}


workdir=$(cd $(dirname $0); pwd)
fileType=".app.dSYM"
otherPath="/Contents/Resources/DWARF"
dsymdir=$workdir$'/'$1$fileType$otherPath$'/'$1
searchPath='./'
crashPath=$workdir$'/'$1'.txt'

armType="arm64"

##-z empty
if [[ -n "$2"  ]]
then
   case $2 in
   "arm64e") armType="arm64e"
   ;;
   "armv7s") armType="armv7s"
   ;;
   "arm64") armType="arm64"
   ;;
   *) exit_shell
  # ;;
   esac
fi

echo $armType

echo "runing........"



crashPath_=`find ${searchPath} -name *.crash`
if [ -f "$crashPath_" ];
then
crashPath=$crashPath_
fi



if [ -f "$workdir"/crash.txt ];
then
rm -f "$workdir"/crash.txt
fi




#echo $dsymdir
#echo "$workdir"

Triggered=false
str="Triggered"

Binary=false
strB="Binary"

UUID=`dwarfdump --uuid "${dsymdir}"`
echo $UUID>>"$workdir"/crash.txt

while read line
do
#echo $line

#result=$(echo $line | grep $1)
thread=${line:0:1}


resultT=$(echo $line | grep $str)

resultB=$(echo $line | grep $strB)

resultThread=$(echo $thread | grep "T")

#filter Triggered
if [[ "$resultT" != "" ]]  
then
    Triggered=true
fi

#filter Binary
if [[ "$resultB" != "" ]]  
then
    Binary=true
fi




if  [[ $Triggered == true ]] && [[ $Binary == false ]]
then
   
    
    if [[ "$resultThread" != "" ]]
    then
        echo "-------------------------------------------------">>"$workdir"/crash.txt
        echo $line>>"$workdir"/crash.txt
        #echo $line        
    else
       #line not empty
       if [[ -n "$line"  ]]
       then
        if [ "$thread" -ge 0 ] 2>/dev/null ;
        then
        
        #----
        #address2=${line#*+ }
        #address_=${line##*0x}
        #address1=${address_%+*}

        address_=${line#*0x}
        
        #app crash line
        appCrash=$(echo $address_ | grep "0x")
        if [[ "$appCrash" != "" ]]
        then
          address_=${address_#*0x}
        fi
        
        address2=${address_##*+ }
        
        
        address1=${address_%% *}
        
        
        
        ((num1=0x$address1))
        ((num2=$address2))
        num3=$(($num1+$num2))
       
        num4=`printf "0x%02x\n" ${num3}`
        
        #echo 0x$address1---:$num4
        
        
        result=`atos -arch ${armType} -o "${dsymdir}" -l 0x${address1} ${num4}`
   
        echo $result>>"$workdir"/crash.txt
        echo "">>"$workdir"/crash.txt
        fi
         fi
    fi
    #fi
#else
    #echo ""
fi
done < "$crashPath"
