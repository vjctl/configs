#!/bin/sh
#
# $1 -- Name of the remote to which the push is being done
# $2 -- URL to which the push is being done
#

REMOTE="$1"
URL="$2"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PROTECTED_BRANCHES="main|master"
# ALLOWED_OWNERS="$USER|org1|org2|org3"

if [[ -e .noverify ]]; then
	exit 0
fi

# if [[ "$REMOTE" = "upstream" ]]; then
# 	echo "HOOK: Pushing to 'upstream' remote"
# 	echo "HOOK: Use git push --no-verify to force this operation"
# 	exit 1
# fi

# if ! echo $URL | grep -Eq "$ALLOWED_OWNERS"; then
# 	echo "HOOK: Pushing to remote URL not containing an allowed owner"
# 	echo "HOOK: Use git push --no-verify to force this operation"
# 	exit 1
# fi

if echo $BRANCH | grep -Eq "$PROTECTED_BRANCHES"; then
	echo "HOOK: Pushing to '$BRANCH' not allowed"
	echo "HOOK: Use git push --no-verify to force this operation"
	exit 1
fi
