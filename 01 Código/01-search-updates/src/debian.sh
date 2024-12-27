#!/bin/bash
apt-get update
if [ $? -eq 0 ]
then
  pac=( $(apt list --upgradable | awk -F/ '{print $1}' | tail -n+2 ) )
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
    repo+=( $(apt-cache policy $pkg | awk '/Installed/{flag=1} flag{buf = buf $0 ORS} /Packages/{flag=0; if(imprimir=1) print buf; buf=""; imprimir=0} flag && /http/{imprimir=1}' | grep http | awk '{print $2}' | awk -F / '{ print $3 }') )
    arr+=( $(apt-cache policy $pkg | awk '/Installed/{flag=1} flag{buf = buf $0 ORS} /Packages/{flag=0; if(imprimir=1) print buf; buf=""; imprimir=0} flag && /http/{imprimir=1}' | grep http | awk '{print $2}' | awk -F / '{ print }') )
    apt changelog $pkg 2>/dev/null | awk '/^Get:/{flag=1} flag{buf = buf $0 ORS} /^ -- /{flag=0; if(imprimir=1) print buf; buf=""; imprimir=0} flag && /CVE/{imprimir=1}' | egrep CVE-20[0-2][0-9]-[0-9]*[,]?$ | awk '{ for (i=1; i<=NF; i++) print $i }' | tr -d ',' | tail -n+2 > /tmp/cves_split_$pkg
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
  # Max number of iterations
  num=`expr $log_arr - 1`
  for (( i=0; i<=$num; i++ ))
  do
   # Opening curly brace
   if [ $i -eq 0 ]
   then
    echo "{" > /tmp/check_pending_security_packages.json
    echo "    \"repositories\":[" >> /tmp/check_pending_security_packages.json
    echo "        {" >> /tmp/check_pending_security_packages.json
    echo "            \"repository\":\"http://security.debian.org\"," >> /tmp/check_pending_security_packages.json
    echo "            \"packages\":[" >> /tmp/check_pending_security_packages.json
   fi
   echo "                {" >> /tmp/check_pending_security_packages.json
   echo "                    \"name\":\"${pac[$i]}\"," >> /tmp/check_pending_security_packages.json
   echo "                    \"release_date\":\"${rls[$i]}\"," >> /tmp/check_pending_security_packages.json
   echo "                    \"security\":{" >> /tmp/check_pending_security_packages.json
   echo "                        \"urgency\":\"${urg[$i]}\"," >> /tmp/check_pending_security_packages.json
   echo "                        \"cves\":[" >> /tmp/check_pending_security_packages.json
   arr1=($(cat /tmp/cves_split_${pac[$i]}))
   log_arr1=( $(cat /tmp/cves_split_${pac[$i]} | wc -l))
   num1=$(expr $log_arr1 - 1)
     if [ ! $log_arr1 -eq 0 ]
   then
    for (( j=0; j<=$num1; j++ ))
    do
     if [ $j -eq $num1 ]
     then
      echo "                            \"${arr1[$j]}\"" >> /tmp/check_pending_security_packages.json
      echo "                        ]" >> /tmp/check_pending_security_packages.json
      echo "                    }" >> /tmp/check_pending_security_packages.json
      if [ ! $i -eq $num ]
      then
       echo "                }," >> /tmp/check_pending_security_packages.json
      else
       echo "                }" >> /tmp/check_pending_security_packages.json
      fi
     else
      echo "                            \"${arr1[$j]}\"," >> /tmp/check_pending_security_packages.json
     fi
    done
   else
    echo "                        ]" >> /tmp/check_pending_security_packages.json
    echo "                    }" >> /tmp/check_pending_security_packages.json
     if [ ! $i -eq $num ]
     then
      echo "                }," >> /tmp/check_pending_security_packages.json
     else
      echo "                }" >> /tmp/check_pending_security_packages.json
     fi
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
  for i in ${!repo[@]}
  do
   [[ -f /tmp/"${repo[$i]}" ]] && rm /tmp/"${repo[$i]}"
   [[ -f /tmp/releases_"${repo[$i]}" ]] && rm /tmp/releases_"${repo[$i]}"
   [[ -f /tmp/urgencies_"${repo[$i]}" ]] && rm /tmp/urgencies_"${repo[$i]}"
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