#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble

readonly SLIDES_SOURCE="${SLIDES_DIR}/slides.typ"
readonly NOTES_SOURCE="${SLIDES_DIR}/slides.pdfpc"

echo "Building 'slides'..."
mkdir -p "${SLIDES_BUILD_DIR}"
typst compile --font-path "~/.fonts" "${SLIDES_SOURCE}" "${SLIDES}"

echo "Extracting notes from 'slides'..."
polylux2pdfpc "${SLIDES_SOURCE}"
mv "${NOTES_SOURCE}" "${SLIDES_BUILD_DIR}"
