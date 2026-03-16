# Cave Resources Extraction - Problem Analysis & Solutions

## Quick Summary

**Problem**: Line 145 in `cave.sh` uses a grep pattern that doesn't find resources:
```bash
grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$TMP/SRC"
```

**Why it fails**: The `[^%]` anchor looks for non-% characters, but HTML between the image and percentage likely contains `<`, `>`, or other special chars that break the pattern.

**Quick fix**: Change `[^%]` to `[^<]` to match "everything until the next HTML tag":
```bash
grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC"
```

---

## How to Diagnose

### Step 1: Check if Resources and Percentages Exist

```bash
# Verify resources exist in HTML
grep -c 'res/' "$TMP/SRC"              # Should be > 0

# Verify percentages exist
grep -c '%' "$TMP/SRC"                 # Should be > 0
```

If both are 0, the cave page didn't load properly. If both are > 0, move to Step 2.

### Step 2: Check Current Pattern Status

```bash
# This should show 0 matches (confirming it's broken)
grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$TMP/SRC" | wc -l
```

### Step 3: Try the Quick Fix

```bash
# Test if this pattern works better
grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC" | wc -l
# Should show > 0 if the fix works
```

---

## Code Fixes

### Fix Option A: Simple One-Line Change (Recommended First Try)

**File**: `/c/Users/hugov/OneDrive/Documentos/GitHub/TitansWarPro/cave.sh`
**Line**: 145

**Current code**:
```bash
    grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$TMP/SRC" | while read -r match; do
```

**Fixed code**:
```bash
    grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC" | while read -r match; do
```

**Why**: Changes anchor from `[^%]` (stop at %) to `[^<]` (stop at HTML tag). This is more reliable because the percentage is guaranteed to be before the next `<` tag.

---

### Fix Option B: Alternative Patterns (If Option A Doesn't Work)

If the quick fix doesn't work, try these in order:

#### B1: Greedy with closing bracket
```bash
grep -oE 'res/[0-9]+\.png[^>]*[0-9]+%' "$TMP/SRC"
```
Use this if resources are within HTML tag attributes.

#### B2: Larger context window
```bash
grep -oE '.{0,50}res/[0-9]+\.png.{0,50}[0-9]+%' "$SRC_FILE"
```
Use this if there's significant whitespace/text between resource and percentage.

#### B3: Two-pass extraction (Most robust but more complex)

Replace the entire `_cave_display_probabilities()` function with:

```bash
_cave_display_probabilities() {
    local log_file="${1:-}"
    local ts
    printf -v ts '%(%H:%M)T' -1

    echo_t "Resources found" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "💎"

    # Extract all res/N.png and collect their line numbers
    declare -a resource_lines
    mapfile -t resource_lines < <(grep -n 'res/[0-9]' "$TMP/SRC" | cut -d: -f1)

    # For each resource line, extract ID and find percentage on same/nearby lines
    for line_num in "${resource_lines[@]}"; do
        [ -z "$line_num" ] && continue

        # Extract resource ID from res/ID.png
        local id
        id=$(sed -n "${line_num}p" "$TMP/SRC" | grep -oE 'res/([0-9]+)' | grep -oE '[0-9]+')
        [ -z "$id" ] && continue

        # Look for percentage on this line or next 3 lines
        local pct
        pct=$(sed -n "${line_num},$((line_num + 3))p" "$TMP/SRC" | grep -oE '[0-9]{1,3}%' | head -1 | tr -d '%')

        local name
        name=$(_cave_resource_name "$id")

        # Log this resource found
        echo "$id:$name" >> "$TMP/cave_resources_found.txt"

        echo_t "  ${name}${pct:+ (${pct}%)}" "${GRAY_BLACK}" "${COLOR_RESET}"
    done
}
```

---

## Understanding the HTML

### Why the Original Pattern Failed

w3m with `-dump_source` returns raw HTML like this (simplified):

```html
<!-- Likely structure 1: Simple inline -->
<div class="resource">
  <img src="res/1.png" alt="Iron"/>
  <span>Iron</span>
  <span class="chance">45%</span>
</div>

<!-- Likely structure 2: With HTML between -->
<div class="resource">
  <img src="res/2.png" alt="Silver"/>
  <br/>
  <span>
    <strong>Silver Ore</strong><br/>45%
  </span>
</div>

<!-- Likely structure 3: Nested spans/divs -->
<div class="resource">
  <span class="icon"><img src="res/1.png"/></span>
  <span class="info">
    <span class="name">Iron</span>
    <span class="percent">45%</span>
  </span>
</div>
```

In **all these cases**:
- The pattern `res/[0-9]+\.png[^%]{0,100}?[0-9]+%` tries to match:
  1. `res/1.png`
  2. Up to 100 non-% characters
  3. A %

**The problem**: Between `res/1.png` and `45%` there's likely `<img`, `<br`, `</br`, `<span`, etc.—and these contain characters that DO match `[^%]`, but they also stop before the `%` gets captured because the HTML nesting breaks the contiguity.

With `[^<]` instead:
- It matches `res/1.png` then everything UNTIL it hits a `<` (the next HTML tag)
- This reliably captures content up to but not including nested tags
- Much more reliable for HTML parsing with grep

---

## Testing Your Fix

After making a change, test it:

```bash
# Make sure caves have resources before testing
source cave.sh 2>/dev/null

# Test the new pattern directly
grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC" | head -10

# If that works, test in context
_cave_display_probabilities "" 2>/dev/null | head -20
```

---

## Recommended Implementation Steps

1. **Use debug scripts first** to understand YOUR HTML structure:
   ```bash
   chmod +x test_cave_patterns.sh
   ./test_cave_patterns.sh /path/to/cave_src_file
   ```

2. **Try Fix Option A first** (change `[^%]` to `[^<]`)

3. **If that doesn't work**, try Fix Option B's patterns in order

4. **If those don't work**, use Fix Option B3 (two-pass extraction)

5. **Once working**, commit with:
   ```bash
   git add cave.sh
   git commit -m "fix: improve cave resource percentage extraction pattern"
   ```

---

## Common Edge Cases

### Case 1: Multiple Percentages on Same Line
```html
<div>res/1.png 40% res/2.png 35%</div>
```
**Solution**: The current patterns handle this—each res/...% combo is extracted separately.

### Case 2: Percentage Before Resource
```html
<div>40% <img src="res/1.png"/></div>
```
**Solution**: Need pattern: `grep -oE '[0-9]+%[^<]*res/[0-9]+\.png'`

### Case 3: No Percentage Shown Yet
```html
<div class="resource"><img src="res/1.png"/></div>
<!-- percentage loaded via JavaScript -->
```
**Solution**: This would require JavaScript execution—w3m doesn't do this. Unlikely.

### Case 4: Percentage as HTML Entity
```html
<div>45&#37;</div>  <!-- &#37; is % in HTML -->
```
**Solution**: Pattern would need: `grep -oE '[0-9]+&#37;|[0-9]+%'`

---

## Files Created for You

I've created three helper scripts in your TitansWarPro directory:

1. **`debug_cave_html.sh`** - Comprehensive analysis tool (10 different patterns)
2. **`debug_cave_patterns.sh`** - Strategy-based pattern tester (7 strategies)
3. **`test_cave_patterns.sh`** - Interactive tester (menu-driven)

Usage:
```bash
# Make them executable
chmod +x debug_cave_html.sh debug_cave_patterns.sh test_cave_patterns.sh

# Get a live cave HTML file
export ACCOUNT_ID="A1"
source /path/to/requeriments.sh
source /path/to/info.sh
fetch_page "/cave/"

# Then run analysis
./test_cave_patterns.sh "$TMP/SRC"
```

---

## Summary Matrix

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| No resources shown, grep returns 0 | Pattern too restrictive | Try `[^<]` instead of `[^%]` |
| Resources shown but no percentages | % extraction broken | Same fix |
| Partial match (some resources) | HTML structure varies | Use two-pass extraction |
| Percentage far from image | Large HTML tree | Use Option B2 |
| HTML entities instead of % | Encoding issue | Add `&#37;` to pattern |

---

## Questions to Answer Before Reporting Bug

1. Does `grep -c 'res/' "$TMP/SRC"` show resources? (Should be > 0)
2. Does `grep -c '%' "$TMP/SRC"` show percentages? (Should be > 0)
3. What does `./test_cave_patterns.sh "$TMP/SRC"` say for patterns 4-6?
4. Show output of: `sed -n '1,10p' "$TMP/SRC"` (first few lines of HTML)

Once you answer these, the specific pattern will be clear.

