
SCHEME=$1
WORKSPACE=$2
DESTINATION=$3
DERIVED_DATA_PATH=$4
HOSTING_BASE_PATH=$5
STATIC_WEB_PATH=$6

echo "-----------------------"
echo "SCHEME=$SCHEME"
echo "WORKSPACE=$WORKSPACE"
echo "DESTINATION=$DESTINATION"
echo "DERIVED_DATA_PATH=$DERIVED_DATA_PATH"
echo "HOSTING_BASE_PATH=$HOSTING_BASE_PATH"
echo "STATIC_WEB_PATH=$STATIC_WEB_PATH"
echo "-----------------------"

#Generate documentation
xcodebuild docbuild -quiet -scheme "$SCHEME" -destination "$DESTINATION" -workspace "$WORKSPACE" -derivedDataPath "$DERIVED_DATA_PATH"

echo "Navigating to: $DERIVED_DATA_PATH/Build/Products/Debug-iphoneos"
if [ -d "$DERIVED_DATA_PATH/Build/Products/Debug-iphoneos" ]; then
    echo "Directory exists. Changing directory."
    cd "$DERIVED_DATA_PATH/Build/Products/Debug-iphoneos"
else
    echo "Error: Directory does not exist!"
    exit 1
fi

#Convert the archive into a static web page
echo "Starting DocC Archive conversion to a static web app"
$(xcrun --find docc) process-archive \
transform-for-static-hosting "$SCHEME".doccarchive \
    --output-path "$STATIC_WEB_PATH" \
    --hosting-base-path "$HOSTING_BASE_PATH"

echo "Conversion completed"

#Move to the submodule that hosts the documentation and remove the current one
if [ -d "../../../../tws-ios-docs" ]; then
    echo "Directory exists. Changing directory."
    cd ../../../../tws-ios-docs
else
    echo "Error: Directory does not exist! (../../../../tws-ios-docs)"
    exit 1
fi

#Copy and commit the updated documentation
if [ ! -d "$PWD" ]; then
  echo "Error: Current working directory does not exist."
  exit 1
fi

echo "Derived data path: $DERIVED_DATA_PATH"
echo "Static web path: $STATIC_WEB_PATH"
#

git checkout main
git pull
pwd
echo "Moved to Docs repository and checked out main branch"
echo "Removing all the current documentatino content"
ls
rm -rf *
echo "Content removed"

echo "Copying from: ../$DERIVED_DATA_PATH/Build/Products/Debug-iphoneos/$STATIC_WEB_PATH"
if [ -d "../$DERIVED_DATA_PATH/Build/Products/Debug-iphoneos/$STATIC_WEB_PATH" ]; then
    echo "Directory exists. Copying from directory."
else
    echo "Error: Directory does not exist!"
    exit 1
fi

cp -R ../"$DERIVED_DATA_PATH"/Build/Products/Debug-iphoneos/"$STATIC_WEB_PATH"
git add .
git commit -m "Updated documentation"
git push origin main
