# Write environment variables to product Info.plist

BUILD_INFOPLIST_FILE="$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

pb=/usr/libexec/PlistBuddy

keys="DEV_USERNAME
      DEV_PASSWORD
      DEV_CLIENT_ID
      DEV_CLIENT_SECRET
      PROD_CLIENT_ID
      PROD_CLIENT_SECRET"

for key in $keys; do
    if [ -z "${!key}" ]; then
        source "$SRCROOT/bin/secrets.sh"
        break
    fi
done

for key in $keys; do
    $pb -c "Delete :$key" "$BUILD_INFOPLIST_FILE"
    $pb -c "Add :$key string ${!key}" "$BUILD_INFOPLIST_FILE"
done
