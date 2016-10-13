#!/bin/bash

## Location of the Couchbase CLI
export CB_BIN=/opt/couchbase/bin/couchbase-cli

## Get the working directory
export SOURCE="${BASH_SOURCE[0]}"
export WD="$( dirname "$SOURCE" )"

## Import the default arguments for this script
source $WD/default_args.bash

function print_args {

	echo "Using the following arguments: "
	echo " ADMIN_NAME=$ADMIN_NAME"
	echo " ADMIN_PWD=$ADMIN_PWD"
	echo " MASTER_NAME=$MASTER_NAME"
	echo " RAM_SIZE=$RAM_SIZE"
	echo " DATA_DIR=$DATA_DIR"
	echo " IDX_DIR=$IDX_DIR"
}

function usage {
	echo "Use: $0 with environment variables ADMIN_NAME, ADMIN_PWD, MASTER_NAME, RAM_SIZE"
	print_args
}


function main {

	if [ "$ADMIN_NAME" = "" -o "$ADMIN_PWD" = "" -o "$MASTER_NAME" = "" -o "$RAM_SIZE" = "" ]
	then
		usage
  	else

		echo "Initializing the node ..."
                $CB_BIN node-init -c $MASTER_NAME:8091 -u $ADMIN_NAME -p $ADMIN_PWD\
                        --node-init-data-path=$DATA_DIR\
                        --node-init-index-path=$IDX_DIR\
                        --node-init-hostname=$MASTER_NAME

		echo "Initializing the cluster ..."
		$CB_BIN cluster-init -c $MASTER_NAME:8091\
			--cluster-init-username=$ADMIN_NAME\
			--cluster-init-password=$ADMIN_PWD\
	 	        --cluster-init-ramsize=$RAM_SIZE\
			--cluster-init-port=8091
	fi
}

main
