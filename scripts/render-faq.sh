#!/usr/bin/env bash
# Render the static reading copies with DITA Open Toolkit 4.3.4.
set -eu
cd "$(git rev-parse --show-toplevel)/assets/faq"
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
for topic in *.dita; do
  dita --input="$topic" --format=html5 --output="$out"
  html=${topic%.dita}.html
  sed -e 's/href="commonltr.css"/href="faq.css"/' \
      -e 's|</head>|<meta name="viewport" content="width=device-width, initial-scale=1"></head>|' \
      -e 's/[[:blank:]]*$//' "$out/$html" > "$html"
done
