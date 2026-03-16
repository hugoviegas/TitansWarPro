#!/bin/bash

# Debug script to test cave resource extraction patterns
# Run this while in a cave to capture and test patterns

echo "=== CAVE RESOURCE EXTRACTION DEBUG ==="
echo ""

if [ ! -f "$TMP/SRC" ]; then
    echo "ERROR: \$TMP/SRC not found. Make sure you're in the cave."
    exit 1
fi

echo "1. Testing if resources exist in HTML:"
res_count=$(grep -c 'res/' "$TMP/SRC")
echo "   Found 'res/' patterns: $res_count"

echo ""
echo "2. Testing if percentages exist:"
pct_count=$(grep -c '%' "$TMP/SRC")
echo "   Found '%' patterns: $pct_count"

echo ""
echo "3. Current pattern test (should show matches):"
echo "   Pattern: grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%'"
matches=$(grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC")
if [ -z "$matches" ]; then
    echo "   ❌ NO MATCHES - pattern is wrong"
else
    echo "   ✅ FOUND MATCHES:"
    echo "$matches" | head -5
fi

echo ""
echo "4. Debugging: Show 200 chars around first 'res/':"
context=$(grep -oE '.{0,100}res/[0-9]+\.png.{0,100}' "$TMP/SRC" | head -1)
echo "   $context"

echo ""
echo "5. Alternative patterns to test:"

echo ""
echo "   A) Using [^>]*: grep -oE 'res/[0-9]+\.png[^>]*[0-9]+%'"
alt_a=$(grep -oE 'res/[0-9]+\.png[^>]*[0-9]+%' "$TMP/SRC" | wc -l)
echo "      Matches: $alt_a"

echo ""
echo "   B) Using .: grep -oE 'res/[0-9]+\.png.{0,50}[0-9]+%'"
alt_b=$(grep -oE 'res/[0-9]+\.png.{0,50}[0-9]+%' "$TMP/SRC" | wc -l)
echo "      Matches: $alt_b"

echo ""
echo "   C) Using \s or tab: grep -oE 'res/[0-9]+\.png[[:space:]]*[0-9]+%'"
alt_c=$(grep -oE 'res/[0-9]+\.png[[:space:]]*[0-9]+%' "$TMP/SRC" | wc -l)
echo "      Matches: $alt_c"

echo ""
echo "6. Save HTML snapshot for manual inspection:"
cp "$TMP/SRC" /tmp/cave_debug_snapshot.html
echo "   Saved to: /tmp/cave_debug_snapshot.html"

echo ""
echo "7. Which pattern worked best?"
echo "   Current [^<]*: $matches"
if [ "$alt_a" -gt 0 ]; then
    echo "   ✅ Pattern [^>]* has $alt_a matches"
fi
if [ "$alt_b" -gt 0 ]; then
    echo "   ✅ Pattern .{0,50} has $alt_b matches"
fi
if [ "$alt_c" -gt 0 ]; then
    echo "   ✅ Pattern [[:space:]]*  has $alt_c matches"
fi
