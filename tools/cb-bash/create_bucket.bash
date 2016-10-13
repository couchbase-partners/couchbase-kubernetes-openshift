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
	echo " BUCKET_SIZE=$BUCKET_SIZE"
	echo " BUCKET_NAME=$BUCKET_NAME"
	echo " BUCKET_PWD=$BUCKET_PWD"
	echo " BUCKET_REPL=$BUCKET_REPL"
}

function usage {
	echo "Use: $0 with environment variables ADMIN_NAME, ADMIN_PWD, MASTER_NAME, BUCKET_NAME, BUCKET_PWD"
	print_args
}


function main {

	if [ "$ADMIN_NAME" = "" -o "$ADMIN_PWD" = "" -o "$MASTER_NAME" = "" -o "$BUCKET_NAME" = "" -o "$BUCKET_PWD" = "" ]
	then
		usage
  	else

		echo "Creating the bucket ..."
		$CB_BIN bucket-create -c ${MASTER_NAME}:8091 -u $ADMIN_NAME -p $ADMIN_PWD\
			      --bucket=$BUCKET_NAME --bucket-password=$BUCKET_PWD --bucket-ramsize=$BUCKET_SIZE\
			      --bucket-type=couchbase --bucket-port=11211 --bucket-replica=$BUCKET_REPL --wait

	fi
}

main
