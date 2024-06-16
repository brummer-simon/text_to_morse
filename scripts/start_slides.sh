#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble

make -s -C "${BASE_DIR}" slides

echo "Start presenting 'slides'..."
pdfpc "${SLIDES}"

