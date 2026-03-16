#!/bin/bash
# Interactive cave HTML pattern tester
# Tests multiple patterns against actual HTML and shows results

set -e

SRC_FILE="${1:-.}"

show_help() {
    cat <<'EOF'
Usage: ./test_cave_patterns.sh [SRC_FILE]

Interactive tester for cave resource extraction patterns.

Commands:
  1   - Test basic resource count (res/N.png)
  2   - Test percentage count
  3   - Test current BROKEN pattern
  4   - Test IMPROVED pattern 1 (greedy to <)
  5   - Test IMPROVED pattern 2 (larger context)
  6   - Test IMPROVED pattern 3 (greedy to >)
  7   - Show line numbers with resources
  8   - Show HTML context around first resource
  9   - Test custom pattern (you type it)
  0   - Exit
  ?   - Show this help

Example flow:
  - Run command 1 and 2 to see if resources and percentages exist
  - Run command 3 to confirm current pattern is broken
  - Run commands 4-6 to test improvements
  - Use command 9 to test your own pattern

EOF
}

if [ ! -f "$SRC_FILE" ]; then
    echo "Error: File not found: $SRC_FILE"
    echo ""
    show_help
    exit 1
fi

echo "=========================================="
echo "CAVE RESOURCE PATTERN TESTER"
echo "=========================================="
echo "File: $SRC_FILE"
echo "Size: $(wc -c < "$SRC_FILE") bytes"
echo ""
echo "Type '?' for help, 'q' to quit"
echo ""

while true; do
    echo -n "> Command (0-9 or ?): "
    read -r cmd

    case "$cmd" in
        1)
            echo ""
            echo "=== Count: All resource images (res/N.png) ==="
            count=$(grep -o 'res/[0-9]\+\.png' "$SRC_FILE" 2>/dev/null | wc -l)
            echo "Count: $count"
            if [ "$count" -gt 0 ]; then
                echo "Sample:"
                grep -o 'res/[0-9]\+\.png' "$SRC_FILE" | head -5
            fi
            echo ""
            ;;

        2)
            echo ""
            echo "=== Count: All percentages (N%) ==="
            count=$(grep -o '[0-9]\{1,3\}%' "$SRC_FILE" 2>/dev/null | wc -l)
            echo "Count: $count"
            if [ "$count" -gt 0 ]; then
                echo "Sample:"
                grep -o '[0-9]\{1,3\}%' "$SRC_FILE" | sort -u | head -10
            fi
            echo ""
            ;;

        3)
            echo ""
            echo "=== Testing CURRENT (BROKEN) Pattern ==="
            echo "Pattern: grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%'"
            count=$(grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$SRC_FILE" 2>/dev/null | wc -l)
            echo "Matches: $count"
            if [ "$count" -gt 0 ]; then
                echo "Samples:"
                grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$SRC_FILE" 2>/dev/null | head -5
            else
                echo "⚠️  No matches! This confirms the pattern is broken."
            fi
            echo ""
            ;;

        4)
            echo ""
            echo "=== Testing IMPROVED Pattern 1 (greedy to HTML tag) ==="
            echo "Pattern: grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%'"
            count=$(grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$SRC_FILE" 2>/dev/null | wc -l)
            echo "Matches: $count"
            if [ "$count" -gt 0 ]; then
                echo "✅ Pattern works! Samples:"
                grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$SRC_FILE" 2>/dev/null | head -5
            else
                echo "❌ No matches. Try other patterns."
            fi
            echo ""
            ;;

        5)
            echo ""
            echo "=== Testing IMPROVED Pattern 2 (larger context window) ==="
            echo "Pattern: grep -oE '.{0,100}res/[0-9]+\.png.{0,100}[0-9]+%'"
            count=$(grep -oE '.{0,100}res/[0-9]+\.png.{0,100}[0-9]+%' "$SRC_FILE" 2>/dev/null | wc -l)
            echo "Matches: $count"
            if [ "$count" -gt 0 ]; then
                echo "✅ Pattern works! Samples:"
                grep -oE '.{0,100}res/[0-9]+\.png.{0,100}[0-9]+%' "$SRC_FILE" 2>/dev/null | head -3 | sed 's/^/  /'
            else
                echo "❌ No matches. Try other patterns."
            fi
            echo ""
            ;;

        6)
            echo ""
            echo "=== Testing IMPROVED Pattern 3 (greedy to closing bracket) ==="
            echo "Pattern: grep -oE 'res/[0-9]+\.png[^>]*[0-9]+%'"
            count=$(grep -oE 'res/[0-9]+\.png[^>]*[0-9]+%' "$SRC_FILE" 2>/dev/null | wc -l)
            echo "Matches: $count"
            if [ "$count" -gt 0 ]; then
                echo "✅ Pattern works! Samples:"
                grep -oE 'res/[0-9]+\.png[^>]*[0-9]+%' "$SRC_FILE" 2>/dev/null | head -5
            else
                echo "❌ No matches. Try other patterns."
            fi
            echo ""
            ;;

        7)
            echo ""
            echo "=== Line numbers containing 'res/' ==="
            if grep -qn 'res/' "$SRC_FILE" 2>/dev/null; then
                grep -n 'res/' "$SRC_FILE" | head -10 | sed 's/^/  Line /'
                total=$(grep -c 'res/' "$SRC_FILE" 2>/dev/null)
                echo "  ... ($total total lines with resources)"
            else
                echo "  (no matches)"
            fi
            echo ""
            ;;

        8)
            echo ""
            echo "=== HTML Context around first resource ==="
            first_line=$(grep -n 'res/' "$SRC_FILE" 2>/dev/null | head -1 | cut -d: -f1)
            if [ -n "$first_line" ]; then
                start=$((first_line - 2))
                [ "$start" -lt 1 ] && start=1
                end=$((first_line + 5))
                echo "Context (lines $start-$end):"
                sed -n "${start},${end}p" "$SRC_FILE" | nl -v "$start" | sed 's/^/  /'
            else
                echo "  (no resources found)"
            fi
            echo ""
            ;;

        9)
            echo ""
            echo "=== Test Custom Pattern ==="
            echo -n "Enter grep pattern (e.g., 'res/[0-9]+\.png[^<]*[0-9]+%'): "
            read -r pattern
            if [ -z "$pattern" ]; then
                echo "Empty pattern. Skipping."
            else
                echo ""
                count=$(grep -oE "$pattern" "$SRC_FILE" 2>/dev/null | wc -l)
                echo "Matches: $count"
                if [ "$count" -gt 0 ]; then
                    echo "✅ Pattern matches! Samples:"
                    grep -oE "$pattern" "$SRC_FILE" 2>/dev/null | head -5 | sed 's/^/  /'
                else
                    echo "❌ No matches with this pattern."
                fi
            fi
            echo ""
            ;;

        0|q|Q)
            echo "Exiting."
            exit 0
            ;;

        \?|h|H)
            echo ""
            show_help
            ;;

        *)
            echo "Unknown command: '$cmd'. Type '?' for help."
            ;;
    esac
done

