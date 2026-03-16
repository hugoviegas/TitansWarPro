#!/bin/bash
# Advanced cave resource extraction pattern analyzer
# This script suggests improved grep patterns based on HTML structure analysis

SRC_FILE="${1:-.}"

if [ ! -f "$SRC_FILE" ]; then
    echo "Error: File not found: $SRC_FILE"
    exit 1
fi

echo "=========================================="
echo "ADVANCED CAVE RESOURCE EXTRACTION ANALYSIS"
echo "=========================================="
echo ""

# Test multiple extraction strategies
echo "=== STRATEGY 1: Context-based extraction ==="
echo "Assumption: Percentage is within ~50-100 chars after res/N.png"
echo "Pattern: grep -oE 'res/[0-9]+\\.png[^<]{0,100}[0-9]+%'"
echo "Count: $(grep -oE 'res/[0-9]+\.png[^<]{0,100}[0-9]+%' "$SRC_FILE" 2>/dev/null | wc -l) matches"
echo ""

echo "=== STRATEGY 2: Greedy extraction (up to HTML tag) ==="
echo "Assumption: Resource and percentage separated by HTML, not raw text"
echo "Pattern: grep -oE 'res/[0-9]+\\.png[^<]*[0-9]+%'"
echo "Count: $(grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$SRC_FILE" 2>/dev/null | wc -l) matches"
echo ""

echo "=== STRATEGY 3: Multiline extraction with sed/awk ==="
echo "Description: Extract all res/N and correlate with next percentage"
echo "Sample matches:"
{
    # Extract lines with res/N.png
    grep -n 'res/[0-9]' "$SRC_FILE" | head -3 | while IFS=: read -r linenum content; do
        echo "  Line $linenum: $(echo "$content" | cut -c 1-80)..."
    done
} || echo "  (no matches)"
echo ""

echo "=== STRATEGY 4: Look for percentage BEFORE resource image ==="
echo "Pattern: grep -oE '[0-9]+%[^<]*res/[0-9]+\\.png'"
echo "Count: $(grep -oE '[0-9]+%[^<]*res/[0-9]+\.png' "$SRC_FILE" 2>/dev/null | wc -l) matches"
echo ""

echo "=== STRATEGY 5: Extract complete resource blocks ==="
echo "Pattern: Look for <div>/<span> blocks containing both res/ and %"
echo "Sample:"
{
    # Try to find blocks with both res and percentage
    perl -ne 'print if /res\/.*?%|%.*?res\// && length <= 500' "$SRC_FILE" 2>/dev/null | head -3
} || echo "  (no matches or perl not available)"
echo ""

echo "=== STRATEGY 6: Check for specific HTML patterns ==="
echo ""
echo "Looking for common Titans War patterns:"
echo ""

# Check for specific element patterns
{
    echo -n "  - 'res/' elements: "
    grep -c 'res/' "$SRC_FILE" || echo "0"
} 2>/dev/null || echo "  - 'res/' elements: error"

{
    echo -n "  - Percentage symbols (%): "
    grep -o '%' "$SRC_FILE" | wc -l
} || echo "  - Percentage symbols (%): error"

{
    echo -n "  - 'src=' attributes: "
    grep -c 'src=' "$SRC_FILE" || echo "0"
} 2>/dev/null || echo "  - 'src=' attributes: error"

{
    echo -n "  - 'class=' attributes: "
    grep -c 'class=' "$SRC_FILE" || echo "0"
} 2>/dev/null || echo "  - 'class=' attributes: error"

echo ""

echo "=== STRATEGY 7: Manual line inspection ==="
echo "First 5 lines containing 'res/':"
grep -n 'res/' "$SRC_FILE" 2>/dev/null | head -5 | while IFS=: read -r linenum content; do
    echo "  Line $linenum (chars 1-100):"
    echo "    $content" | cut -c 1-100
done || echo "  (no matches)"
echo ""

echo "=========================================="
echo "RECOMMENDATIONS"
echo "=========================================="
echo ""
echo "1. If STRATEGY 2 shows good results (many matches):"
echo "   Use: grep -oE 'res/[0-9]+\\.png[^<]*[0-9]+%'"
echo "   Then extract ID and % separately in a loop"
echo ""
echo "2. If manual inspection (STRATEGY 7) shows clear pattern:"
echo "   Build specific pattern based on that structure"
echo ""
echo "3. If resources and percentages are far apart:"
echo "   Use a two-pass approach:"
echo "     a) Extract res/N and note line numbers"
echo "     b) Extract percentages on those lines or nearby"
echo ""
echo "4. For complex HTML, consider using:"
echo "   - w3m's HTML dump with -dump_table_cellpadding option"
echo "   - pup (if available) for CSS selectors"
echo "   - jq (if data is in JSON)"
echo ""

