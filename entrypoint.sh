#!/bin/bash
set -e

if [[ -z "$GITHUB_REPOSITORY" ]]; then
    echo "The env variable GITHUB_REPOSITORY is required"
    exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
    echo  "The env variable GITHUB_EVENT_PATH is required"
    exit 1
fi

GITHUB_TOKEN="$1"

l_max_size="$2"
fail_if_xl="$3"

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

echo "Github event"
echo "$GITHUB_EVENT_PATH"

number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

autolabel() {
    body=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}")

    additions=$(echo "$body" | jq '.additions')
    deletions=$(echo "$body" | jq '.deletions')
    total_modifications=$(echo "$additions + $deletions" | bc)
    label_to_add=$(label_for "$total_modifications")

    echo "Labeling pull request with $label_to_add"
    curl -sSL \
      -H "${AUTH_HEADER}" \
      -H "${API_HEADER}" \
      -X POST \
      -H "Content-Type: application/json" \
      -d "{\"labels\":[\"${label_to_add}\"]}" \
      "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels"

    if [ "$label_to_add" == "size/xl" ] && [ "$fail_if_xl" =="true" ]; then
        echo "PR is too big, short this!"
        exit 1
    fi
}

label_for() {
    if [ "$1" -lt 10 ]; then
        label="size/xs"
    elif [ "$1" -lt 100 ]; then
        label="size/s"
    elif [ "$1" -lt 500 ]; then
        label="size/m"
    elif [ "$1" -lt "$l_max_size" ]; then
        label="size/l"
    else
        label="size/xl"
    fi

    echo "$label"
}

autolabel

exit $?