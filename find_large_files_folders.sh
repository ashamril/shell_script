#!/bin/bash

usage(){
	echo "Usage: $0"
	exit 1
}

## [[ $# -eq 0 ]] && usage
echo "Large files"
echo "==========="
find -type f -exec du -Sh {} + | sort -rh | head -n 10

find -type f -printf "%s %p\n" | sort -rn | head -n 10

echo ""
echo "Large folders"
echo "============="
du -Sh | sort -rh | head -10

du -a | sort -n -r | head -n 10
