#!/bin/bash
set -e

###
patterns_file="peripheryIgnoringPatterns.txt"
periphery_output_file="periphery_output.txt"
periphery_output_file_tmp="periphery_outputTmp.txt"

# Expected output for a successful build
expected_output=$(cat <<EOF
* Inspecting project...
* Indexing...
* Analyzing...

EOF
)
###

###
if [ -n "$1" ]; then
    index_store_path=$1
else
    index_store_path="periphery/DerivedData"
    xcodebuild -workspace TheWebSnippet.xcworkspace -scheme Sample -derivedDataPath "$index_store_path" -destination 'generic/platform=iOS' CODE_SIGN_STYLE="Manual" CODE_SIGN_IDENTITY="iPhone Developer" PROVISIONING_PROFILE_SPECIFIER="TWS_dev" DEVELOPMENT_TEAM=G33XFLC26J CODE_SIGNING_ALLOWED=NO

    if [ $? -ne 0 ]; then
        echo "xcodebuild failed"
        rm -rf periphery/DerivedData
        exit 1
    fi
fi
###
realpath "$index_store_path"
all_filter_patterns=$(cat "$patterns_file")

brew install periphery

if periphery scan --disable-update-check --skip-build --index-store-path "$index_store_path/Index.noindex/DataStore/" --config .periphery.yml > "$periphery_output_file" 2> periphery_error.log; then
    #remove results with pattern
    grep -vE "$all_filter_patterns" "$periphery_output_file" > "$periphery_output_file_tmp"
    mv "$periphery_output_file_tmp" "$periphery_output_file"

    actual_output=$(cat "$periphery_output_file")
    if [ "$actual_output" != "$expected_output" ]; then
        echo "THERE IS DEAD CODE IN PROJECT. CHECK PERIPHERY OUTPUT"
        echo "$actual_output"
        exit 1
    fi
    echo "Haven't found any deadcode"
    echo "$actual_output"
else
    echo "Periphery failed. Error output:"
    cat periphery_error.log
    exit 1
fi
