# Write environment variables to product Info.plist

BUILD_INFOPLIST_FILE="$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

if [ -z "$DEV_CLIENT_ID" ] \
|| [ -z "$DEV_CLIENT_SECRET" ] \
|| [ -z "$PROD_CLIENT_ID" ] \
|| [ -z "$PROD_CLIENT_SECRET" ]; then
    source "$SRCROOT/bin/secrets.sh"
fi

pb=/usr/libexec/PlistBuddy

for key in DEV_CLIENT_ID DEV_CLIENT_SECRET PROD_CLIENT_ID PROD_CLIENT_SECRET; do
    $pb -c "Delete :$key" "$BUILD_INFOPLIST_FILE"
    $pb -c "Add :$key string ${!key}" "$BUILD_INFOPLIST_FILE"
done
