#!/bin/bash

set -x
set -e

create_vm_script() {
	VM_SCRIPT=$1
	
	unameOut="$(uname -s)"
	case "${unameOut}" in
	    Linux*)     OSNAME=Linux;;
	    Darwin*)    OSNAME=Darwin;;
	    MSYS*|CYGWIN*|MINGW*)     OSNAME=Windows;;
	    *)          OSNAME="UNKNOWN:${unameOut}"
	esac

	VM_DIR=.
	VM_BINARY_NAME="Pharo"
	VM_BINARY_NAME_LINUX="pharo"
	VM_BINARY_NAME_WINDOWS="PharoConsole"

	if [ "$OSNAME" == "Windows" ]; then
	    PHARO_VM=`find $VM_DIR -name ${VM_BINARY_NAME_WINDOWS}.exe`
	elif [ "$OSNAME" == "Darwin" ]; then
	    PHARO_VM=`find $VM_DIR -name ${VM_BINARY_NAME}`
	elif [ "$OSNAME" == "Linux" ]; then
	    PHARO_VM=`ls $VM_DIR/${VM_BINARY_NAME_LINUX}`
	fi
	
	echo "#!/usr/bin/env bash" > $VM_SCRIPT
	echo '# some magic to find out the real location of this script dealing with symlinks
DIR=`readlink "$0"` || DIR="$0";
DIR=`dirname "$DIR"`;
cd "$DIR"
DIR=`pwd`
cd - > /dev/null 
# disable parameter expansion to forward all arguments unprocessed to the VM
set -f
# run the VM and pass along all arguments as is' >> $VM_SCRIPT
	
	# make sure we only substite $PHARO_VM but put "$DIR" in the script
	echo -n \"\$DIR\"/\"$PHARO_VM\" >> $VM_SCRIPT
		
	# forward all arguments unprocessed using $@
	echo " \"\$@\"" >> $VM_SCRIPT
	
	# make the script executable
	chmod +x $VM_SCRIPT
}

REPO_DIR=$(readlink -f $(dirname -- "${BASH_SOURCE[0]}")/../)
BASEDIR=$(pwd)
VM=$BASEDIR/install_vm/pharo

mkdir -p image
mkdir -p install_vm

pushd install_vm

if [ ! -f vm.zip ]; then
	curl --progress-bar -o vm.zip https://files.pharo.org/vm/pharo-spur64-headless/$(uname -s)-$(uname -m)/stable10.zip
fi

unzip -o -d . vm.zip  
create_vm_script "pharo"

popd

pushd image

if [ ! -f image.zip ]; then
	curl --progress-bar -o image.zip https://files.pharo.org/image/140/latest-64.zip
fi

unzip -o -d . image.zip
ORIGINAL_IMAGE=$(ls Pharo14.0-SNAPSHOT-*.image)
$VM $ORIGINAL_IMAGE save Bloc

$VM Bloc.image eval --save $(cat <<EOF
	| repositories baselines installedBaselines | 

	Metacello new
		baseline: 'BlocBenchs';
		repository: 'github://pharo-graphics/BlocBenchs:master/src';
		load.

	{
		'alexandrie'.
		'bloc'.
		'album'.
		'toplo'.
		'spec-toplo'.
	} do: [ :repoName |
		(IceRepository registry
			select: [ :each | each name asLowercase = repoName ])
			do:[ :each |
				(each branchNamed: 'dev') checkout.
				each fetch; pull ] ]
		displayingProgress: [ :each | each ].

	repositories := (IceRepository repositories reject: [ :e |
		e project tags includes: 'system' asSymbol ]).

	baselines := (repositories flatCollect: [ :e | e workingCopy packages ])
		select: [:e | e name beginsWith: 'BaselineOf' ] thenCollect: [ :e | e name withoutPrefix: 'BaselineOf'].

	installedBaselines := baselines select: [ :e | Metacello registrations anySatisfy: [ :r | r projectName = e ]].
	
	installedBaselines do: [ :e | 
		Metacello new
			baseline: e;
			lock
		 ].

	Metacello new
		baseline: 'VeritasBloc';
		onConflictUseLoaded;
		repository: 'gitlocal://$REPO_DIR';
		load.
EOF
)

popd