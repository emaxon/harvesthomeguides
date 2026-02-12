#!/usr/bin/env bash
# Generate DOCX and EPUB manuscripts for Harvest Home Guides
# Usage: ./generate-manuscripts.sh <region|all>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REFERENCE="$SCRIPT_DIR/reference.docx"
REGIONS=(texas florida southeast midwest northeast pacific-northwest southwest northern-california mountain-west great-plains)

get_display_name() {
  case "$1" in
    texas) echo "Texas" ;;
    florida) echo "Florida" ;;
    southeast) echo "Southeast" ;;
    midwest) echo "Midwest" ;;
    northeast) echo "Northeast" ;;
    pacific-northwest) echo "Pacific Northwest" ;;
    southwest) echo "Southwest" ;;
    northern-california) echo "Northern California" ;;
    mountain-west) echo "Mountain West" ;;
    great-plains) echo "Great Plains" ;;
    *) echo "$1" ;;
  esac
}

get_filename() {
  local region="$1"
  # Find the markdown file in the region directory
  local md_file
  md_file=$(find "$SCRIPT_DIR/$region" -maxdepth 1 -name "*.md" ! -name "outline.md" | head -1)
  echo "$md_file"
}

generate_region() {
  local region="$1"
  local input
  input="$(get_filename "$region")"
  local outdir="$SCRIPT_DIR/$region/output"
  local name
  name="$(get_display_name "$region")"

  if [[ -z "$input" || ! -f "$input" ]]; then
    echo "⚠️  Skipping $region: no markdown file found"
    return 1
  fi

  mkdir -p "$outdir"

  local title="${name} Vegetable Gardening"
  local full_title="Harvest Home Guides: ${title}"

  echo "📄 Generating DOCX for $name..."
  pandoc "$input" \
    --reference-doc="$REFERENCE" \
    --metadata title="$full_title" \
    --metadata author="Evan Maxon" \
    -f markdown \
    -t docx \
    -o "$outdir/${title}.docx"

  echo "📱 Generating EPUB for $name..."
  pandoc "$input" \
    --metadata title="$full_title" \
    --metadata author="Evan Maxon" \
    --toc \
    --toc-depth=2 \
    -f markdown \
    -t epub \
    -o "$outdir/${title}.epub"

  local docx_size epub_size
  docx_size=$(ls -lh "$outdir/${title}.docx" | awk '{print $5}')
  epub_size=$(ls -lh "$outdir/${title}.epub" | awk '{print $5}')
  echo "✅ $name: DOCX ($docx_size) | EPUB ($epub_size)"
}

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <region|all>"
  echo "Regions: ${REGIONS[*]}"
  exit 1
fi

TARGET="$1"

if [[ "$TARGET" == "all" ]]; then
  echo "🚀 Generating all Harvest Home manuscripts..."
  for region in "${REGIONS[@]}"; do
    generate_region "$region" || true
  done
  echo "🎉 Done!"
else
  generate_region "$TARGET"
fi
