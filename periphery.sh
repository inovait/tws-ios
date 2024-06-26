#!/bin/bash
set -e

###
patterns_file="peripheryIgnoringPatterns.txt"
periphery_output_file="periphery_output.txt"
periphery_output_file_tmp="periphery_outputTmp.txt"

#number of lines of empty periphery output
emptyPeripheryNumOfLines=10
###
###
if [ -n "$1" ]; then
    index_store_path=$1
else
    index_store_path="periphery/DerivedData"
    xcodebuild -workspace TheWebSnippet.xcworkspace -scheme TWSDemo -derivedDataPath "$index_store_path" -destination 'generic/platform=iOS'

    if [ $? -ne 0 ]; then
        echo "xcodebuild failed"
        rm -rf periphery/DerivedData
        exit 1
    fi
fi
###
realpath "$index_store_path"
all_filter_patterns=$(cat "$patterns_file")

if periphery scan --skip-build --index-store-path "$index_store_path/Index.noindex/DataStore/" --config .periphery.yml > "$periphery_output_file"; then
    #remove results with pattern
    grep -vE "$all_filter_patterns" "$periphery_output_file" > "$periphery_output_file_tmp"
    mv "$periphery_output_file_tmp" "$periphery_output_file"

    line_count=$(wc -l < "$periphery_output_file")

    if [ "$line_count" -gt "$emptyPeripheryNumOfLines" ]; then
        echo "THERE IS DEAD CODE IN PROJECT. CHECK PERIPHERY OUTPUT"
        cat "$periphery_output_file"
        exit 1
    fi
    echo "Haven't found any deadcode"
    cat "$periphery_output_file"
else
    echo "Periphery failed, reason could be that project build folder in not created or path to it is wrong"
    exit 1
fi
