function pull_changes {
	if [ ! -d "repo" ]; then
		echo "Cloning $1..."
		git clone $1 repo
		cd repo
		git config pull.ff only
	else
		cd repo
		echo "Pulling changes for $1"
		HEAD=$(git branch -vv | grep -Po "^[\s\*]*\K[^\s]*(?=.*$(git branch -r | grep -Po 'HEAD -> \K.*$'))")
		git checkout ${HEAD:6}
		git pull
	fi
}

function build_package {
	start_tag="$1"
	arch_list="$2"
	pkgname="$3"
	force="$4"
	TAGS=$(git tag)
	START=0

	# Begin looping through the tags.
	for tag in $TAGS; do
		if [ $START -eq 0 ]; then
			# Check to see if this version should be skipped.
			if [ "$tag" == "$start_tag" ] || [ $START == "1" ]; then
				# Begin building now
				START="1"
			else
				# Continue on to the next version
				continue
			fi
		fi
		# Build this version for each architecture
		# Checkout this tag and leave the git repo
		git checkout $tag
		cd ../
		for arch in ${arch_list[*]}; do
			# Run the build_package script for each version/arch
			# combination,
			./build_package.sh $pkgname $tag $arch 1 $force
		done
		cd repo
	done
}

function build_specific_tags {
	NAME=$1
	TAGS=$2
	ARCH_LIST=$3
	force=$4
	
	for tag in ${TAGS[*]}; do
		git checkout $tag
		cd ../
		for arch in ${ARCH_LIST[*]}; do
			./build_package.sh $NAME $tag $arch 1 $force
		done
		cd repo
	done
}

function move_packages {
	TO=$1
	FROM=$2

	# Check for each type
	if [ -d "$FROM/x86" ]; then
		cp $FROM/x86/* $TO/x86/packages/
	fi

	if [ -d "$FROM/x86_64" ]; then
		cp $FROM/x86_64/* $TO/x86_64/packages/
	fi

	if [ -d "$FROM/x86_gcc2" ]; then
		cp $FROM/x86_gcc2/* $TO/x86_64/packages/
	fi
}

BASE_DIR="$(pwd)/pkgs"
TO="$(pwd)/repo/"

for pkg in $(ls pkgs); do
	cd $BASE_DIR/$pkg
	source PKGCONF
	# install the requirements
	./requirements.sh
	pull_changes $git_repo_url
	if [ $only_these_tags == true ]; then
		echo "Building with only specific tags"
		build_specific_tags $pkg $tag_list $arch_list
	else
		build_package $start_tag $arch_list $pkg
	fi
	move_packages $TO $BASE_DIR/$pkg/packages/built
done
