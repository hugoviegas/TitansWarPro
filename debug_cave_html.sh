#!/bin/bash
# Debug script to analyze cave HTML structure and test grep patterns
# Usage: ./debug_cave_html.sh <path_to_src_file>

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path_to_SRC_file>"
    echo ""
    echo "This script helps debug cave HTML structure and test different grep patterns"
    echo "to extract resources and their percentages."
    exit 1
fi

SRC_FILE="$1"

if [ ! -f "$SRC_FILE" ]; then
    echo "Error: File not found: $SRC_FILE"
    exit 1
fi

echo "=========================================="
echo "CAVE HTML DEBUG ANALYSIS"
echo "=========================================="
echo "File: $SRC_FILE"
echo "Size: $(wc -c < "$SRC_FILE") bytes"
echo ""

# ========== PATTERN 1: Current pattern (likely failing) ==========
echo "--- PATTERN 1: Current pattern ---"
echo "Pattern: grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%'"
echo "Result:"
grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$SRC_FILE" | head -10 || echo "(no matches)"
echo ""

# ========== PATTERN 2: Find all res/N.png occurrences ==========
echo "--- PATTERN 2: All resource images (res/N.png) ---"
echo "Pattern: grep -oE 'res/[0-9]+\.png'"
echo "Result:"
RES_MATCHES=$(grep -oE 'res/[0-9]+\.png' "$SRC_FILE")
if [ -n "$RES_MATCHES" ]; then
    echo "$RES_MATCHES" | sort | uniq -c
else
    echo "(no matches)"
fi
echo ""

# ========== PATTERN 3: Find all percentages ==========
echo "--- PATTERN 3: All percentages (N%) ---"
echo "Pattern: grep -oE '[0-9]{1,3}%'"
echo "Result:"
grep -oE '[0-9]{1,3}%' "$SRC_FILE" | sort | uniq -c | sort -rn | head -20 || echo "(no matches)"
echo ""

# ========== PATTERN 4: Context around res/N.png ==========
echo "--- PATTERN 4: Context around resource images (10 chars before/after) ---"
echo "Using: grep -o -B 10 -A 10 'res/[0-9]+\.png' (simplified)"
echo "Result:"
grep -oE '.{0,50}res/[0-9]+\.png.{0,50}' "$SRC_FILE" | head -5 || echo "(no matches)"
echo ""

# ========== PATTERN 5: Look for color indicators ==========
echo "--- PATTERN 5: Color indicators (green/red classes) ---"
echo "Patterns: green|red found in"
echo "Result:"
grep -o -E 'class="(green|red)|style="[^"]*color[^"]*' "$SRC_FILE" | head -10 || echo "(no matches)"
echo ""

# ========== PATTERN 6: Extract res/N + next percentage on same/nearby lines ==========
echo "--- PATTERN 6: Extract resource + percentage pairs ---"
echo "Strategy: Find each res/N.png and capture following text up to )"
echo "Result:"
grep -oE 'res/[0-9]+\.png[^)]{0,200}' "$SRC_FILE" | head -5 || echo "(no matches)"
echo ""

# ========== PATTERN 7: Line-by-line analysis around res/ ==========
echo "--- PATTERN 7: Line numbers containing res/ ---"
grep -n 'res/' "$SRC_FILE" | head -10 || echo "(no matches)"
echo ""

# ========== PATTERN 8: Check for percentage patterns in HTML attributes ==========
echo "--- PATTERN 8: Percentage in data-attributes or titles ---"
grep -oE 'data-[^"]*="[^"]*%' "$SRC_FILE" | head -5 || echo "(no matches)"
grep -oE 'title="[^"]*%' "$SRC_FILE" | head -5 || echo "(no matches)"
echo ""

# ========== PATTERN 9: Look for "Recursos encontrados" or similar ==========
echo "--- PATTERN 9: References to 'Recursos' or resource lists ---"
grep -o -E 'Recursos|resources|Found|found' "$SRC_FILE" | sort | uniq -c || echo "(no matches)"
echo ""

# ========== PATTERN 10: Full HTML structure context ==========
echo "--- PATTERN 10: HTML structure around res/ ---"
echo "First 2 KB around first resource image:"
RES_POS=$(grep -m 1 -b -o 'res/' "$SRC_FILE" | cut -d: -f1)
if [ -n "$RES_POS" ] && [ "$RES_POS" -gt 0 ]; then
    dd if="$SRC_FILE" bs=1 skip=$((RES_POS - 500)) count=1500 2>/dev/null | head -c 1500 | cat -v
else
    echo "(resource image not found)"
fi
echo ""

# ========== SUMMARY ==========
echo "=========================================="
echo "SUMMARY FOR DEBUGGING"
echo "=========================================="
echo ""
echo "If PATTERN 2 shows resources but PATTERN 1 shows nothing:"
echo "  -> The percentage extraction pattern is broken"
echo ""
echo "If PATTERN 3 shows many percentages:"
echo "  -> Percentages exist but are not near resource images"
echo ""
echo "If PATTERN 7 shows line numbers:"
echo "  -> You can inspect those specific lines more carefully"
echo ""
echo "Next steps:"
echo "  1. Understand the HTML structure (use PATTERN 10)"
echo "  2. Look at specific lines (grep -n 'res/' | head -1 then sed -n 'Np')"
echo "  3. Build a pattern that captures both resource AND percentage together"
echo "  4. Test with: grep -oE '<new_pattern>' \$SRC_FILE"
echo ""
