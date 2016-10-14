#!  /bin/bash -x

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0"
fi

shopt -s nocasematch

function rebalance {
    if test "$CB_REBALANCE_COUNT" == ""; then
        CB_REBALANCE_COUNT=0
    fi

    echo "Checking whether we want to rebalance..."
    
    known_hosts=`/opt/couchbase/bin/couchbase-cli server-list -c localhost:$CB_UI_PORT -u $CB_USER -p $CB_PASS | grep "healthy" | wc -l`
    
    if [ "$known_hosts" -ge "$CB_REBALANCE_COUNT" ]; then
        while [[ ! $(/opt/couchbase/bin/couchbase-cli rebalance-status -u $CB_USER -p $CB_PASS -c localhost:$CB_UI_PORT | grep -i "notRunning") ]] ; do
           echo "Rebalance already running, sleeping and will try again."
           sleep 5
        done

        echo "Rebalancing since there are at least $CB_REBALANCE_COUNT nodes in the cluster."
        
        rs_tag -a "rebalance:$righttag=`date -u +%H%M%S%3N`-`echo $nodename`"
        echo "Checking for other rebalancers"
        private_ips=`rs_tag -q "rebalance:$righttag" | grep -i rebalance | cut -d '=' -f 2 | cut -d '"' -f 1 | sort | cut -d '-' -f2- | cut -d ';' -f1`
        position=`echo $private_ips | grep -o -b "$nodename" | cut -d ':' -f 1`;
    
        if [ "$position" == "0" ]; then
          echo "I am the first to rebalance"
          wget -q -O- --user=$CB_USER --password=$CB_PASS --post-data='ns_config:set(rebalance_moves_per_node, 8).' http://localhost:$CB_UI_PORT/diag/eval > /dev/null;

          rebalance=`/opt/couchbase/bin/couchbase-cli rebalance -u $CB_USER -p $CB_PASS -c localhost:$CB_UI_PORT`
          echo "Rebalance: $rebalance"

          while [[ $(curl -s -u $CB_USER:$CB_PASS http://localhost:$CB_UI_PORT/pools/default/tasks > /dev/null | grep -i "Rebalance failed") ]]; do
            echo "Rebalance failed, trying again"
            rebalance=`/opt/couchbase/bin/couchbase-cli rebalance -u $CB_USER -p $CB_PASS -c localhost:$CB_UI_PORT`
            echo "Rebalance: $rebalance"
            sleep 5;
          done        

          echo "Rebalance completed successfully."
          exit 0 #leave with a smile...
        else
          echo "Another node will rebalance first"
          exit 0
        fi
    else
        echo "Skipping rebalance since there are only $known_hosts nodes in the cluster"
    fi
}



if  test "$RS_REBOOT" == "true" || test "$CB_CLUSTERING" == "FALSE"; then
  echo "Don't want to run the Clustering Script"
  exit 0 # Leave with a smile ...
fi
if test "$CB_USER" == "" || test "$CB_PASS" == ""; then
    echo "Can't join a cluster without proper credentials.  Please set your Couchbase username/pass."
    exit -1 #leave without a smile
fi
if test "$CB_CLUSTER_TAG" == ""; then
   echo "You must supply a tag to identify the cluster by."
   exit -1
fi
###########
echo "Running Clustering Script"
###########

if test "$VPC" != 1; then
  echo "Not inside a VPC, using $EC2_PUBLIC_HOSTNAME"
  nodename=$EC2_PUBLIC_HOSTNAME
else
  echo "Inside a VPC, using $EC2_LOCAL_IPV4"
  nodename=$EC2_LOCAL_IPV4
fi

if [ -e "/var/spool/cloud/user-data/RS_EIP" ]
then
  echo "Found EIP: `cat /var/spool/cloud/user-data/RS_EIP`, setting to `host \`cat /var/spool/cloud/user-data/RS_EIP\` | cut -d ' ' -f 5 | sed s/.$//`"
  nodename=`host \`cat /var/spool/cloud/user-data/RS_EIP\` | cut -d ' ' -f 5 | sed s/.$//`
fi

righttag=`echo $CB_CLUSTER_TAG | sed s/\ /_/`

CB_SERVICES=`echo $CB_SERVICES | sed '$s/,$//'`

if test "$CB_INITIAL_LAUNCH" == "FALSE"; then
    echo "Setting my own tag to $righttag:"
    date=`date -u +%H%M%S%3N`
    tag=`rs_tag -a "couchbase:$righttag=$date-$nodename;$CB_SERVICES"`
    if [[ "$tag" =~ "failed" ]]; then
      echo "Error setting tags, exiting"
      exit -1;
    fi

    exit 0 #leave with a smile
fi

echo "Seting up NTP:"
service ntpd stop
ntpdate 0.pool.ntp.org;
service ntpd start

version=`cat /opt/couchbase/VERSION.txt | cut -d '-' -f 1`
major_ver=`echo $version | cut -d '.' -f 1`
minor_ver=`echo $version | cut -d '.' -f 2`
ramsize=$CB_RAMSIZE

if test "$ramsize" == ""; then
    ramsize=`echo "\`free -m | grep Mem| awk '{print $2}'\` * .8" | bc -l | cut -d'.' -f 1`
fi

dataramquota=$(( ( ramsize * 3 ) / 4 ));
indexramquota=$(( ( ramsize * 1 ) / 4 ));

echo "Setting disk paths, hostname to: $nodename :"
mkdir -p /couchbase/data
mkdir -p /couchbase/index
chown -R couchbase:couchbase /couchbase
  
####  node-init options per version
opts=""
case $major_ver in 
  [1-3])
    ;;
  [4])
    case $minor_ver in
      [0-1])
        CB_SERVICES=`sed 's/,fts\|fts,\|fts//g' <<<$CB_SERVICES`
        ;;
      *)
        #opts="$opts --index-storage-setting=$CB_INDEX_MODE"
        ;;
    esac
    #opts="$opts --services=$CB_SERVICES"
    ;;
esac
while [[ $(/opt/couchbase/bin/couchbase-cli node-init -c localhost:8091 -u $CB_USER -p $CB_PASS \
        --node-init-hostname=$nodename --node-init-data-path=/couchbase/data --node-init-index-path=/couchbase/index \
        $opts | grep -i "error") ]]; do
  sleep 2;
done

echo "Setting my own tag to $righttag:"
date=`date -u +%H%M%S%3N`
tag=`rs_tag -a "couchbase:$righttag=$date-$nodename;$CB_SERVICES"`
if [[ "$tag" =~ "failed" ]]; then
  echo "Error setting tags, exiting"
  exit -1;
fi

while true; do
    echo "Checking whether I am clustered already:"
    known_hosts=`/opt/couchbase/bin/couchbase-cli server-list -c localhost:$CB_UI_PORT -u $CB_USER -p $CB_PASS | wc -l`
    if test "$known_hosts" != 1; then
        echo "I am already part of a cluster"
        rebalance
        exit 0
    fi
    echo "Searching for other members of cluster: $righttag:"

    private_ips=`rs_tag -q "couchbase:$righttag" | grep -i "couchbase:$righttag=" | cut -d '=' -f 2 | cut -d '"' -f 1 | sort | cut -d '-' -f2- | cut -d ';' -f1`
    if [[ "$private_ips" =~ "failed" ]]; then
      echo "Error querying tags, retrying"
      continue;
    fi
    
    if test "$private_ips" == ""; then
       echo "No nodes found"
       exit 0; #leave to start own cluster
    fi

    echo "Node list: $private_ips";

    position=`echo $private_ips | grep -o -b "$nodename" | cut -d ':' -f 1`;
    
    if [ "$position" == "0" ]; then
      echo "I am the first node"
      i=0;
      while true; do
        echo "Starting my own cluster ($i):"
        if ! [[ $CB_SERVICES =~ "data" ]] ; then
          echo "First node must have data service, resetting tag and breaking out of loop"
          rs_tag -a "couchbase:$righttag=`date -u +%H%M%S%3N`-`echo $nodename`;$CB_SERVICES"
          continue 2;
        fi
        
        ####  cluster-init options per version
        opts=""
        case $major_ver in 
          [1-3])
            opts="--cluster-ramsize=$dataramquota"
            ;;
          [4])
            opts="$opts --services=$CB_SERVICES --cluster-ramsize=$dataramquota --cluster-index-ramsize=$indexramquota"
            case $minor_ver in
              [5-6])
                opts="$opts --index-storage-setting=$CB_INDEX_MODE"
                ;;
              [7])
                opts="$opts --index-storage-setting=$CB_INDEX_MODE --cluster-fts-ramsize=$indexramquota"
                ;;
            esac
            ;;
        esac
        start=`/opt/couchbase/bin/couchbase-cli cluster-init -c localhost:8091 -u $CB_USER -p $CB_PASS \
            --cluster-port=$CB_UI_PORT --cluster-username=$CB_USER --cluster-password=$CB_PASS \
            $opts`
            
        echo "Tried to set username/pass, cluster port to $CB_UI_PORT, $clusterinit_opts: $start"
        if [[ "$start" =~ "SUCCESS" ]]; then
          break
        else
          sleep 10;
        fi
        i=$((i+1))
      done     
      exit 0;
    fi
    
    echo "Node list: $private_ips";
    while read ip; do
       echo "Attempting to join node: $ip:$CB_UI_PORT"
      
       #if [[ "$version" =~ "4.0" ]]; then
       #   opts="--services=$CB_SERVICES"
       #elif [[ "$version" =~ "4.1" ]]; then
       #   opts="--services=$CB_SERVICES"
       #elif [[ "$version" =~ "4.5" ||  "$version" =~ "4.6" || "$version" =~ "4.7"  ]]; then
       #   opts="--services=$CB_SERVICES"
       #else
       #   opts=""
       #fi
       ####  join options per version
       opts=""
       case $major_ver in 
         [4])
           opts="$opts --services=$CB_SERVICES"
           case $minor_ver in
             [0-7])
             ;;
           esac
           ;;
       esac
       
       join=`/opt/couchbase/bin/couchbase-cli server-add -c $ip:$CB_UI_PORT -p $CB_PASS -u $CB_USER \
          --server-add=$nodename --server-add-username=$CB_USER --server-add-password=$CB_PASS \
          $opts`
          
       if [[ "$join" =~ "added" ]]; then
           echo "Joined: $ip"
           rebalance
           exit 0
       fi

       echo "Not Joined: $join.";

    done <<< "$private_ips"
done

if test "$private_ips" != ""; then
    echo "There are nodes to join but I was not able to join any...something is wrong."
    echo "Removing my own tag:"
    rs_tag -r "couchbase:$righttag"
    exit -1
fi

echo "No nodes found."
exit 0;
