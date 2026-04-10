#!/usr/bin/env bash
set -e

ADDON="SacrificeUI"
TOC="SacrificeUI.toc"
BUMP_MAJOR=0

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --major) BUMP_MAJOR=1 ;;
    esac
done

# Read current version from .toc
CURRENT=$(grep "^## Version:" "$TOC" | sed 's/.*: *//')
MAJOR=$(echo "$CURRENT" | cut -d. -f1)
MINOR=$(echo "$CURRENT" | cut -d. -f2)
PATCH=$(echo "$CURRENT" | cut -d. -f3)

# Bump version
if [ "$BUMP_MAJOR" -eq 1 ]; then
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
else
    MINOR=$((MINOR + 1))
    PATCH=0
fi

VERSION="${MAJOR}.${MINOR}.${PATCH}"

# Update .toc with new version
sed -i "s/^## Version:.*/## Version: ${VERSION}/" "$TOC"

# Also update Core.lua version string
sed -i "s/SacrificeUI\.version = \"[^\"]*\"/SacrificeUI.version = \"${VERSION}\"/" Core.lua

echo "Version bumped: ${CURRENT} -> ${VERSION}"

STAGING="dist/${ADDON}"
OUT="dist/${ADDON}-${VERSION}.zip"

echo "Packaging ${ADDON} v${VERSION}..."

rm -rf dist
mkdir -p "${STAGING}"

# Core addon files
cp *.lua *.toc "${STAGING}/"

# Build ZIP
(cd dist && zip -r "${ADDON}-${VERSION}.zip" "${ADDON}" --quiet)

echo "Done: ${OUT}"
