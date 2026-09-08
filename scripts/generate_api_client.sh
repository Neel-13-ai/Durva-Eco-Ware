#!/usr/bin/env bash
# Standalone OpenAPI Dart Client Generator
set -euo pipefail

SPEC_PATH="${1:-specs/openapi/api-spec.json}"
OUTPUT_DIR="lib/infrastructure/api/generated"

if [ ! -f "${SPEC_PATH}" ]; then
  echo "Error: OpenAPI specification not found at ${SPEC_PATH}" >&2
  exit 1
fi

echo "Generating Dart API Client into ${OUTPUT_DIR}..."
npx --yes @openapitools/openapi-generator-cli generate \
  -i "${SPEC_PATH}" \
  -g dart \
  -o "${OUTPUT_DIR}" \
  --global-property=apiTests=false,modelTests=false,apiDocs=false,modelDocs=false

echo "API Client generated successfully."
