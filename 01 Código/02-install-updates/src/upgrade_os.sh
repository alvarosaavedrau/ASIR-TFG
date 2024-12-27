#!/bin/bash
# parameters:
# For list updates:  $1="list" $2="distribution"
# For get json: $1="update" $2="upgrade status code" $3="upgrade execution trace" $4="distribution"

#Script to make the exit of the second .json
if [[ $1 == "list" ]]; then
    rm -rf /tmp/install_pending_security_packages.json
          if [[ $2 == "suse" ]] ; then
             updates=( $(zypper lp --category=security | grep '| security' | awk '{print $3}') )
                 if [[ "${#updates[@]}" -lt 0 ]]; then
                   echo "ERROR"
                   exit -1
                 elif [[ "${#updates[@]}" -eq 0 ]]; then
                   echo "No updates"
                   exit 1
                 elif [[ "${#updates[@]}" -ne 0 ]]; then
                    echo "${updates[@]}"
                    exit 0
                 fi
          elif [[ $2 == "ubuntu" ]] ; then
             updates=( $(apt list --upgradable | grep security | awk -F / '{ print $1 }') )
                 if [[ $updates -lt 0 ]]; then
                   echo "ERROR"
                   exit -1
                 elif [[ "${#updates[@]}" -eq 0 ]]; then
                   echo "No updates"
                   exit 1
                 elif [[ "${#updates[@]}" -ne 0 ]]; then
                    echo "${updates[@]}"
                    exit 0
                 fi
          elif [[ $2 == "centos" ]] ; then
             updates=( $(yum updateinfo list sec | awk '{print $3}' | tail -n+2) )
                 if [[ "${#updates[@]}" -lt 0 ]]; then
                   echo "ERROR"
                   exit -1
                 elif [[ "${#updates[@]}" -eq 0 ]]; then
                   echo "No updates"
                   exit 1
                 elif [[ "${#updates[@]}" -ne 0 ]]; then
                    echo "${updates[@]}"
                    exit 0
                 fi
          elif [[ $2 == "debian" ]] ; then
            apt-get update >/dev/null &&  apt list --upgradable  | awk -F/ '{print $1}' | tail -n+2 > /tmp/updates_info.txt
                if [ -s /tmp/updates_info.txt ]
                then
                 for pkg in "`cat /tmp/updates_info.txt`"
                    do
                    apt show $pkg -a | grep "APT-Sources" | awk '{print $2}' >> "/tmp/pkg"
                    done
                    fi
                    arr1=($(cat /tmp/pkg))
                    arr2=($(cat /tmp/updates_info.txt))
                    for ((i=0; i<${#arr1[@]}; i++ ))
                    do
                    echo "${arr1[i]}" | grep "security" >/dev/null
                    if [ `echo $?` -eq 0 ]
                    then
                        echo "${arr2[i]}" >> /tmp/updates.txt
                    fi
                    done
                    if [ -s /tmp/updates.txt ]
                   then
                    updates=($(cat /tmp/updates.txt))
                   fi
                   if [[ $updates -lt 0 ]]; then
                   echo "ERROR"
                   exit -1
                 elif [[ "${#updates[@]}" -eq 0 ]]; then
                   echo "No updates"
                   exit 1
                 elif [[ "${#updates[@]}" -ne 0 ]]; then
                    echo "${updates[@]}"
                    exit 0
          fi
       fi
elif  [[ $1 == "update" && $2 -eq -1 ]]; then
  # Error
  echo "{" > /tmp/install_pending_security_packages.json
  echo "    \"repositories\":[" >> /tmp/install_pending_security_packages.json
  echo "        {" >> /tmp/install_pending_security_packages.json
  echo "            \"repository\":\"repository\"," >> /tmp/install_pending_security_packages.json
  echo "            \"metadata\":{" >> /tmp/install_pending_security_packages.json
  echo "                \"status\":"\"ERROR"\"," >> /tmp/install_pending_security_packages.json
  echo "                \"reason_status\":""," >> /tmp/install_pending_security_packages.json
  echo "                \"execution_trace\": \"$3\"" >> /tmp/install_pending_security_packages.json
  echo "            }" >> /tmp/install_pending_security_packages.json
  echo "        }" >> /tmp/install_pending_security_packages.json
  echo "    ]," >> /tmp/install_pending_security_packages.json
  echo "    \"patch_date\":\"$(ls /tmp/ --full-time | grep install_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}')\"" > /tmp/patch.txt "," >> /tmp/install_pending_security_packages.json
  echo "    \"metadata\":{" >> /tmp/install_pending_security_packages.json
  echo "        \"machine-hostname\":\"$(hostname)\"," >> /tmp/install_pending_security_packages.json
  echo "        \"generation_data_date\":\"$(ls /tmp/ --full-time | grep install_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}' )\"" >> /tmp/install_pending_security_packages.json
  echo "    }" >> /tmp/install_pending_security_packages.json
  echo "}" >> /tmp/install_pending_security_packages.json

elif  [[ $1 == "update" && $2 -eq 1 ]]; then
       #   echo "No updates"
    echo "{" > /tmp/install_pending_security_packages.json
    echo "    \"repositories\":[" >> /tmp/install_pending_security_packages.json
    echo "        {" >> /tmp/install_pending_security_packages.json
    echo "            \"repository\":\"repository\", " >> /tmp/install_pending_security_packages.json
    echo "            \"metadata\":{" >> /tmp/install_pending_security_packages.json
    echo "                \"status\":\"OK\"," >> /tmp/install_pending_security_packages.json
    echo "                \"reason_status\":\"There are no packages with security updates\"," >> /tmp/install_pending_security_packages.json
    echo "                \"execution_trace\": \"$3\"" >> /tmp/install_pending_security_packages.json
    echo "            }" >> /tmp/install_pending_security_packages.json
    echo "        }" >> /tmp/install_pending_security_packages.json
    echo "    ]," >> /tmp/install_pending_security_packages.json
    echo "    \"patch_date\":\"$(ls /tmp/ --full-time | grep install_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}')\"" > /tmp/patch.txt "," >> /tmp/install_pending_security_packages.json
    echo "    \"metadata\":{" >> /tmp/install_pending_security_packages.json
    echo "         \"machine-hostname\":\"$(hostname)\"," >> /tmp/install_pending_security_packages.json
    echo "         \"generation_data_date\":\"$(ls /tmp/ --full-time | grep install_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}' )\"" >> /tmp/install_pending_security_packages.json
    echo "    }" >> /tmp/install_pending_security_packages.json
    echo "}" >> /tmp/install_pending_security_packages.json

elif  [[ $1 == "update" && $2 -eq 0  && $3 == "suse" ]]; then
      # Updates found
  echo "{" > /tmp/install_pending_security_packages.json
  echo "    \"repositories\":[" >> /tmp/install_pending_security_packages.json
  echo "        {" >> /tmp/install_pending_security_packages.json
  echo "            \"repository\":\"repository\"," >> /tmp/install_pending_security_packages.json
  echo "            \"metadata\":{" >> /tmp/install_pending_security_packages.json
  echo "                \"status\":"\"OK"\"," >> /tmp/install_pending_security_packages.json
  echo "                \"reason_status\":\"Packages updated\",">> /tmp/install_pending_security_packages.json
  echo "                \"execution_trace\": \"$4\"," >> /tmp/install_pending_security_packages.json
  echo "            }" >> /tmp/install_pending_security_packages.json
  echo "        }" >> /tmp/install_pending_security_packages.json
  echo "    ]," >> /tmp/install_pending_security_packages.json
  echo "    \"patch_date\":\"$(sudo grep -i "applied" /var/log/zypp/history | grep ${updates[1]} | tail -1 | awk '{print $1}')\"" > /tmp/patch.txt "," >> /tmp/install_pending_security_packages.json
  echo "    \"metadata\":{" >> /tmp/install_pending_security_packages.json
  echo "        \"machine-hostname\":\"$(hostname)\"," >> /tmp/install_pending_security_packages.json
  echo "        \"generation_data_date\":\"$(ls /tmp/ --full-time | grep install_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}' )\"" >> /tmp/install_pending_security_packages.json
  echo "    }" >> /tmp/install_pending_security_packages.json
  echo "}" >> /tmp/install_pending_security_packages.json

elif  [[ $1 == "update" && $2 -eq 0  && ( $3 == "ubuntu" || $3 == "debian" ) ]]; then
      # Updates found
  echo "{" > /tmp/install_pending_security_packages.json
  echo "    \"repositories\":[" >> /tmp/install_pending_security_packages.json
  echo "        {" >> /tmp/install_pending_security_packages.json
  echo "            \"repository\":\"repository\"," >> /tmp/install_pending_security_packages.json
  echo "            \"metadata\":{" >> /tmp/install_pending_security_packages.json
  echo "                \"status\":"\"OK"\"," >> /tmp/install_pending_security_packages.json
  echo "                \"reason_status\":\"Packages updated\",">> /tmp/install_pending_security_packages.json
  echo "                \"execution_trace\": \"$4\"," >> /tmp/install_pending_security_packages.json
  echo "            }" >> /tmp/install_pending_security_packages.json
  echo "        }" >> /tmp/install_pending_security_packages.json
  echo "    ]," >> /tmp/install_pending_security_packages.json
  echo "    \"patch_date\":\"$(grep -i "install\|installed\|half-installed" /var/log/dpkg.log | grep ${updates[1]} | tail -1 | awk '{print $1}')\"" > /tmp/patch.txt "," >> /tmp/install_pending_security_packages.json
  echo "    \"metadata\":{" >> /tmp/install_pending_security_packages.json
  echo "        \"machine-hostname\":\"$(hostname)\"," >> /tmp/install_pending_security_packages.json
  echo "        \"generation_data_date\":\"$(ls /tmp/ --full-time | grep install_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}' )\"" >> /tmp/install_pending_security_packages.json
  echo "    }" >> /tmp/install_pending_security_packages.json
  echo "}" >> /tmp/install_pending_security_packages.json

elif  [[ $1 == "update" && $2 -eq 0  && $3 == "centos" ]]; then
      # Updates found
  echo "{" > /tmp/install_pending_security_packages.json
  echo "    \"repositories\":[" >> /tmp/install_pending_security_packages.json
  echo "        {" >> /tmp/install_pending_security_packages.json
  echo "            \"repository\":\"repository\",">> /tmp/install_pending_security_packages.json
  echo "            \"metadata\":{" >> /tmp/install_pending_security_packages.json
  echo "                \"status\":"\"OK"\"," >> /tmp/install_pending_security_packages.json
  echo "                \"reason_status\":\"Packages updated\",">> /tmp/install_pending_security_packages.json
  echo "                \"execution_trace\": \"$4\"," >> /tmp/install_pending_security_packages.json
  echo "            }" >> /tmp/install_pending_security_packages.json
  echo "        }" >> /tmp/install_pending_security_packages.json
  echo "    ]," >> /tmp/install_pending_security_packages.json
  echo "    \"patch_date\":\"$(sudo grep -i "Updated" /var/log/yum.log | grep ${updates[1]} | tail -1 | awk '{print $1}')\"" > /tmp/patch.txt "," >> /tmp/install_pending_security_packages.json
  echo "    \"metadata\":{" >> /tmp/install_pending_security_packages.json
  echo "        \"machine-hostname\":\"$(hostname)\"," >> /tmp/install_pending_security_packages.json
  echo "        \"generation_data_date\":\"$(ls /tmp/ --full-time | grep install_pending_security_packages.json | awk '{print $6,$7}' | awk -F. '{print $1}' )\"" >> /tmp/install_pending_security_packages.json
  echo "    }" >> /tmp/install_pending_security_packages.json
  echo "}" >> /tmp/install_pending_security_packages.json
fi