# Write environment variables to product Info.plist

BUILD_INFOPLIST_FILE="$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

function write_to_plist() {
    /usr/libexec/PlistBuddy -c "Delete :$1" "$BUILD_INFOPLIST_FILE"
    /usr/libexec/PlistBuddy -c "Add :$1 string ${!1}" "$BUILD_INFOPLIST_FILE"
}

if [ -z "$DEV_CLIENT_ID" ] \
|| [ -z "$DEV_CLIENT_SECRET" ] \
|| [ -z "$PROD_CLIENT_ID" ] \
|| [ -z "$PROD_CLIENT_SECRET" ]; then
    source "$SRCROOT/bin/secrets.sh"
fi

write_to_plist DEV_CLIENT_ID
write_to_plist DEV_CLIENT_SECRET
write_to_plist PROD_CLIENT_ID
write_to_plist PROD_CLIENT_SECRET
