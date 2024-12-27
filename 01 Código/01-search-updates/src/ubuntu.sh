#!/bin/bash
apt-get update
if [ $? -eq 0 ]
then
 # Get the latest list of security updates and save it within a file
 pac=( $(apt list --upgradable | grep security | awk -F/ '{printf "%s\n" , $1}') )
 if [[ ! ${pac[@]} ]]
 then
  ##This runs when there are not security updates:
    cat > /tmp/check_pending_security_packages.json <<End
{
    "repositories":[
        {
            "repository":"",
            "packages":[],
            "metadata":{
                "status":"No packages to update",
                "reason_status":"There are no packages with security updates"
            }
        }
    ],
    "metadata":{
         "machine-hostname":"$(hostname)",
         "generation_data_date":"$(ls /tmp/ --full-time | grep check_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}' )"
    }
}
End
 else
  ##This runs when there are security updates
  for pkg in "${pac[@]}"
  do
    urg+=( $(apt-get changelog $pkg | grep 'urgency' 2>/dev/null | head -n 1 | awk -F = '{ print $2 }') )
    rls+=( $(apt changelog $pkg 2>/dev/null | awk '/^Get:/{flag=1} flag{buf = buf $0 ORS} /^ -- /{flag=0; if(imprimir=1) print buf; buf=""; imprimir=0}flag && /CVE/{imprimir=1}' | egrep [A-Z][a-z][a-z], | awk -F "," '{ print $2 }' | awk '{print $3"-"$2"-"$1}' | sed 's/Jan/01/g; s/Feb/02/g; s/Mar/03/g; s/Apr/04/g; s/May/05/g ; s/Jun/06/g; s/Jul/07/g; s/Aug/08/g; s/Sep/09/g; s/Oct/10/g; s/Nov/11/g; s/Dec/12/g') )
    repositories+=( $(apt-cache policy $pkg | awk '/Installed/{flag=1} flag{buf = buf $0 ORS} /Packages/{flag=0; if(imprimir=1) print buf; buf=""; imprimir=0} flag && /http/{imprimir=1}' | grep http | awk '{print $2}' | awk -F / '{ print $3 }') )
    arr+=( $(apt-cache policy $pkg | awk '/Installed/{flag=1} flag{buf = buf $0 ORS} /Packages/{flag=0; if(imprimir=1) print buf; buf=""; imprimir=0} flag && /http/{imprimir=1}' | grep http | awk '{print $2}' | awk -F / '{ print }') )
    apt changelog $pkg 2>/dev/null | awk '/^Get:/{flag=1} flag{buf = buf $0 ORS} /^ -- /{flag=0; if(imprimir=1) print buf; buf=""; imprimir=0} flag && /CVE/{imprimir=1}' | egrep CVE-20[0-2][0-9]-[0-9]*[,]?$ | awk '{ for (i=1; i<=NF; i++) print $i }' | tr -d ',' | tail -n+2 > /tmp/cves_split_$pkg
  done
for i in ${!repositories[@]}
    do
     echo ${pac[$i]} >> /tmp/"${repositories[$i]}"
     echo ${rls[$i]} >> /tmp/releases_"${repositories[$i]}"
     echo ${urg[$i]} >> /tmp/urgencies_"${repositories[$i]}"
   done
 for m in "${repositories[@]}"
 do
  echo $m >> /tmp/tosort
 done
 repositories=( $(sort -u /tmp/tosort) )
 rm /tmp/tosort
 for m in "${arr[@]}"
 do
  echo $m >> /tmp/tosort
 done
 arr=( $(sort -u /tmp/tosort) )
 rm /tmp/tosort
  log_arr=${#repositories[@]}
  num=`expr $log_arr - 1`
  for (( i=0; i<=$num; i++ ))
  do
   # Opening curly brace
   if [ $i -eq 0 ]
   then
    echo "{" > /tmp/check_pending_security_packages.json
    echo "    \"repositories\":[" >> /tmp/check_pending_security_packages.json
   fi
   if [ $num -ge 0 ]
   then
    echo "          {" >> /tmp/check_pending_security_packages.json
   fi
   echo "            \"repository\":\"${arr[$i]}\"," >> /tmp/check_pending_security_packages.json
   echo "            \"packages\":[" >> /tmp/check_pending_security_packages.json
   arr1=( $(cat /tmp/${repositories[$i]}) ) # Package names
   arr2=( $(cat /tmp/releases_${repositories[$i]}) ) # Release date for each package
   arr3=( $(cat /tmp/urgencies_${repositories[$i]}) ) # Urgency for each package
   len_arr=$(cat /tmp/${repositories[$i]} | wc -l) # Lenght of each repo, done with package names, but it should be the same with releases or urgencies, as they are the same lenght
   num1=`expr $len_arr - 1` # Number of iterations
   for (( j=0; j<=$num1; j++))
   do
   echo "                {" >> /tmp/check_pending_security_packages.json
   echo "                    \"name\":\"${arr1[$j]}\"," >> /tmp/check_pending_security_packages.json
   echo "                    \"release_date\":\"${arr2[$j]}\"," >> /tmp/check_pending_security_packages.json
   echo "                    \"security\":{" >> /tmp/check_pending_security_packages.json
   echo "                        \"urgency\":\"${arr3[$j]}\"," >> /tmp/check_pending_security_packages.json
   echo "                        \"cves\":[" >> /tmp/check_pending_security_packages.json
   arr4=($(cat /tmp/cves_split_${arr1[$j]}))
   log_arr1=($(cat /tmp/cves_split_${arr1[$j]} | wc -l))
   num2=`expr $log_arr1 - 1`
   if [ ! $log_arr1 -eq 0 ]
   then
    for (( k=0; k<=$num2; k++ ))
    do
     if [ $k -eq $num2 ]
     then
      echo "                            \"${arr4[$k]}\"" >> /tmp/check_pending_security_packages.json
      echo "                        ]" >> /tmp/check_pending_security_packages.json
      echo "                    }" >> /tmp/check_pending_security_packages.json
      if [ ! $j -eq $num1 ]
      then
       echo "                }," >> /tmp/check_pending_security_packages.json
      else
       echo "                }" >> /tmp/check_pending_security_packages.json
      fi
     else
      echo "                            \"${arr4[$k]}\"," >> /tmp/check_pending_security_packages.json
     fi
    done
   else
    echo "                        ]" >> /tmp/check_pending_security_packages.json
    echo "                    }" >> /tmp/check_pending_security_packages.json
     if [ ! $j -eq $num1 ]
     then
      echo "                }," >> /tmp/check_pending_security_packages.json
     else
      echo "                }" >> /tmp/check_pending_security_packages.json
     fi
   fi
  done
   if [ $num -gt 0 ] && [ $i -ne $num ]
    then
     echo "            ]," >> /tmp/check_pending_security_packages.json
     echo "            \"metadata\":{" >> /tmp/check_pending_security_packages.json
     echo "                \"status\":\"OK\"," >> /tmp/check_pending_security_packages.json
     echo "                \"reason_status\":\"There are packages with security updates\"" >> /tmp/check_pending_security_packages.json
     echo "            }" >> /tmp/check_pending_security_packages.json
     echo "          }," >> /tmp/check_pending_security_packages.json
    fi
   if [ $i -eq $num ]
   then
    echo "            ]," >> /tmp/check_pending_security_packages.json
    echo "            \"metadata\":{" >> /tmp/check_pending_security_packages.json
    echo "                \"status\":\"OK\"," >> /tmp/check_pending_security_packages.json
    echo "                \"reason_status\":\"There are packages with security updates\"" >> /tmp/check_pending_security_packages.json
    echo "            }" >> /tmp/check_pending_security_packages.json
    echo "        }" >> /tmp/check_pending_security_packages.json
    echo "    ]," >> /tmp/check_pending_security_packages.json
    echo "    \"metadata\":{" >> /tmp/check_pending_security_packages.json
    echo "        \"machine-hostname\":\"$(hostname)\"," >> /tmp/check_pending_security_packages.json
    echo "        \"generation_data_date\":\"$(ls /tmp/ --full-time | grep check_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}' )\"" >> /tmp/check_pending_security_packages.json
    echo "    }" >> /tmp/check_pending_security_packages.json
    echo "}" >> /tmp/check_pending_security_packages.json
   fi
  done
  # Replace * if there is in some CVE
  sed -i s/"*CVE/"CVE/g "/tmp/check_pending_security_packages.json"
  sed -i /'"-",'/d "/tmp/check_pending_security_packages.json"
  # Removing temp files
  for cve in ${pac[@]}
  do
   rm /tmp/cves_split_$cve
  done
  for i in ${!repositories[@]}
  do
   [[ -f /tmp/"${repositories[$i]}" ]] && rm /tmp/"${repositories[$i]}"
   [[ -f /tmp/releases_"${repositories[$i]}" ]] && rm /tmp/releases_"${repositories[$i]}"
   [[ -f /tmp/urgencies_"${repositories[$i]}" ]] && rm /tmp/urgencies_"${repositories[$i]}"
  done
 fi
else
##If there is an error, the following is executed:
   cat > /tmp/check_pending_security_packages.json <<End1
{
    "repositories":[
        {
            "repository":"",
            "packages":[],
            "metadata":{
                "status":"ERROR",
                "reason_status":"$(apt-get update)"
            }
        }
    ],
    "metadata":{
         "machine-hostname":"$(hostname)",
         "generation_data_date":"$(ls /tmp/ --full-time | grep check_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}' )"
    }
}
End1
fi