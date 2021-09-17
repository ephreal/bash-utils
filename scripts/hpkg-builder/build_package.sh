# Builds the passed in version of this package.
# If $5 is force, the package will be rebuilt.

# Check to see if the package has already been built.
# This is skipped if $3 if force.

BASE_DIR=$(pwd)
PKG=$1
BASE_VER=$2
VER=${BASE_VER:1}-$4
ARCH=$3

PKGNAME="$PKG-$VER-$ARCH"
PKG_PATH="packages/builds/$PKGNAME"

echo $PKGNAME

if [ "$5" == "force" ]; then
	echo "Rebuilding the package"
elif [ "$5" == "" ]; then
	echo "Checking to see if package is already built."
	if [ -f "packages/built/$ARCH/$PKGNAME.hpkg" ]; then
		# the package already exists.
		echo "$PKGNAME.hpkg already exists. Skipping..."
		exit
	fi
fi

# Begin the build process.
# The git repo should already be checked out to the correct tag
echo "Building package $PKGNAME"

mkdir -p "$PKG_PATH"
cp $PKG.PackageInfo "$PKG_PATH/.PackageInfo"
sed -i "s/VERSION/version \"$VER\"/g" "$PKG_PATH/.PackageInfo"
sed -i "s/ARCHITECTURE/architecture \"$ARCH\"/g" "$PKG_PATH/.PackageInfo"
sed -i "s/PROVIDES/provides \{\n\t$PKG = $BASE_VER\n\tlib:$PKG = $BASE_VER\n\}/g" "$PKG_PATH/.PackageInfo"

mkdir -p "$PKG_PATH/develop/headers/uthash"
cp -r repo/src/* "$PKG_PATH/develop/headers/uthash"

cd "$PKG_PATH"
package create -b $PKGNAME.hpkg
package add $PKGNAME.hpkg develop

# Package is built, move it to the correct area now

# Ensure that the package arch dir exists
if [ ! -d $BASE_DIR/packages/built/$ARCH ]; then
	mkdir -p $BASE_DIR/packages/built/$ARCH
fi

mv $PKGNAME.hpkg $BASE_DIR/packages/built/$ARCH/
cd $BASE_DIR
