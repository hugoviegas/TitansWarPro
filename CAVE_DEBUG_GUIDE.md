# Cave Resources HTML Parsing Debug Guide

## Problem Summary

The `_cave_display_probabilities()` function in `cave.sh` (line 145) uses this grep pattern:

```bash
grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$TMP/SRC"
```

**Result**: "Recursos encontrados" appears but no resources are listed—the grep pattern returns no matches.

---

## Understanding the Current Pattern

The pattern attempts to:
1. Find `res/[0-9]+\.png` (e.g., `res/1.png`)
2. Match up to 100 non-% characters (non-greedy with `?`)
3. Match a percentage like `50%`

**Why it fails**:
- The `[^%]{0,100}?` non-greedy anchor may not capture enough context
- HTML structure might have the percentage far from the image reference
- Special characters like `<`, `>` in between might break the pattern
- The percentage might be on a different line in the raw HTML

---

## Likely Titans War HTML Structures

Based on typical game HTML, here are likely patterns:

### Structure A: Percentage Near Resource Image (Same Tag Block)
```html
<div>
  <img src="res/1.png" alt="Iron">
  <span class="percentage">45%</span>
</div>
```
**Pattern**: `grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%'`

### Structure B: Percentage in Separate Element (Same Parent)
```html
<div class="resource">
  <img src="res/2.png"/>
  <div>Silver Ore</div>
  <span>38%</span>
</div>
```
**Pattern**: Split extraction - get line numbers with `res/`, then grep those lines for `%`

### Structure C: Percentage as Data Attribute
```html
<div class="resource" data-id="1" data-percent="45">
  <img src="res/1.png"/>
</div>
```
**Pattern**: `grep -oE 'data-percent="[0-9]+"'` paired with `data-id`

### Structure D: Percentage in Title/Alt Text
```html
<img src="res/1.png" title="Iron (45%)" alt="Iron 45%"/>
```
**Pattern**: `grep -oE 'src="res/[0-9]+\.png"[^>]*(title|alt)="[^"]*[0-9]+%'`

### Structure E: SVG or Complex Nested HTML
```html
<span class="res">
  <svg>...</svg>
  45%
</span>
```
**Pattern**: Extract text nodes within same ancestor

---

## Debugging Steps (Use Provided Scripts)

### Step 1: Run Initial Analysis
```bash
chmod +x debug_cave_html.sh
./debug_cave_html.sh /path/to/SRC_file
```

This will show:
- Current pattern matches (if any)
- All `res/N.png` found
- All percentages found
- Context around resources

### Step 2: Run Pattern Strategy Analysis
```bash
chmod +x debug_cave_patterns.sh
./debug_cave_patterns.sh /path/to/SRC_file
```

This tests 7 different extraction strategies and recommends the best one.

### Step 3: Inspect Specific Lines Manually
Once you identify which lines have resources, inspect them:

```bash
# Find first few lines with resources
grep -n 'res/' "$TMP/SRC" | head -5

# Examine a specific line (e.g., line 123)
sed -n '123p' "$TMP/SRC" | cat -A  # Shows all special chars

# Show context (10 lines before/after)
sed -n '113,133p' "$TMP/SRC"
```

### Step 4: Test New Patterns
Once you understand the structure, test patterns:

```bash
# Test potential pattern
grep -oE 'YOUR_PATTERN_HERE' "$TMP/SRC" | head -10

# If it works, extract both ID and percentage in a loop
grep -oE 'YOUR_PATTERN_HERE' "$TMP/SRC" | while read -r match; do
    id=$(echo "$match" | grep -oE '[0-9]+' | head -1)
    pct=$(echo "$match" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
    echo "Resource $id: $pct%"
done
```

---

## Recommended Extraction Improvements

### Option 1: Greedy Until HTML Tag (Most Likely to Work)

Replace line 145 in `cave.sh`:

**Current**:
```bash
grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$TMP/SRC"
```

**Improved**:
```bash
grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC"
```

**Why**: Uses `[^<]` instead of `[^%]`—stops at the next HTML tag, which is more reliable.

### Option 2: Two-Pass Extraction (Most Robust)

```bash
# Get line numbers where resources appear
declare -a LINES
LINES=($(grep -n 'res/' "$TMP/SRC" | cut -d: -f1))

# For each line, extract ID and get percentage nearby
for line_num in "${LINES[@]}"; do
    # Extract res/ID
    id=$(sed -n "${line_num}p" "$TMP/SRC" | grep -oE 'res/([0-9]+)' | grep -oE '[0-9]+')

    # Get percentage on same or next few lines
    pct=$(sed -n "${line_num},+5p" "$TMP/SRC" | grep -oE '[0-9]{1,3}%' | head -1 | tr -d '%')

    [ -n "$id" ] && [ -n "$pct" ] && echo "$id:$pct"
done
```

### Option 3: Extract Using Larger Context Window

```bash
# Get 200 chars around res/N.png
grep -oE '.{0,100}res/[0-9]+\.png.{0,100}[0-9]+%' "$TMP/SRC"
```

### Option 4: Collapse Newlines First (For Multiline HTML)

```bash
# Collapse newlines in resource sections, then extract
grep -o '<[^>]*res/[^<]*>[^<]*</[^>]*>' "$TMP/SRC" | \
  grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%'
```

---

## Modification Instructions

### Quick Fix (Try First)

Edit `/c/Users/hugov/OneDrive/Documentos/GitHub/TitansWarPro/cave.sh` at line 145:

```bash
# OLD LINE:
grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$TMP/SRC" | while read -r match; do

# NEW LINE:
grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC" | while read -r match; do
```

### If That Doesn't Work

Try the two-pass extraction method above as Option 2—it's more robust but slightly more complex.

---

## HTML Structure Detection

To help identify which structure you're dealing with, look for these indicators in `$TMP/SRC`:

```bash
# Check for data attributes
grep -c 'data-percent\|data-id' "$TMP/SRC"

# Check for title/alt attributes with percentages
grep -c 'title="[^"]*%' "$TMP/SRC"

# Check for nested structure (multiple closing tags)
grep -o 'res/[0-9]*\.png' "$TMP/SRC" | head -1 | xargs -I {} grep -B 2 -A 2 '{}' "$TMP/SRC" | head -10
```

---

## Using the Debug Scripts

### 1. Making Scripts Executable

```bash
chmod +x ~/TitansWarPro/debug_cave_html.sh
chmod +x ~/TitansWarPro/debug_cave_patterns.sh
```

### 2. Running During a Live Cave Session

First, capture a cave HTML file manually:

```bash
# Set up account (example)
export ACCOUNT_ID="A1"
export TMP="/path/to/twm/accounts/A1/tmp"

# Fetch cave page
source /path/to/twm/info.sh  # for functions
fetch_page "/cave/"

# Now analyze
/path/to/debug_cave_html.sh "$TMP/SRC"
```

### 3. Interpreting Output

- **If PATTERN 2 shows resources but PATTERN 1 shows nothing**: Percentage extraction is broken
- **If PATTERN 3 shows many %**: Percentages exist but aren't near resources
- **If PATTERN 7 shows clear patterns**: Build custom pattern from those lines

---

## Performance Considerations

Current pattern uses `grep -oE` which is efficient. Proposed improvements:

- **Option 1 (`[^<]*`)**: Same speed as current
- **Option 2 (two-pass)**: Slightly slower (loops), more robust
- **Option 3 (larger context)**: May be slower on large HTML
- **Option 4 (collapse newlines)**: Faster on multiline structures

For cave HTML (typically ~50-100 KB), performance difference is negligible.

---

## Testing Your Fix

Once you modify the pattern, test it:

```bash
# Test the extraction
grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC" | wc -l  # Should be > 0

# Test the full function
source cave.sh
_cave_display_probabilities  # Should now show resources
```

---

## Common Pitfalls

1. **Forgetting to escape dots in regex**: `.png` vs `\.png` (use backslash)
2. **Using greedy too much**: `.*` can match too much—use `[^<]*` instead
3. **Assuming percentage is on same line**: May need to check multiple lines
4. **Not handling "no resources" case**: Add `[ -z "$match" ] && continue`
5. **Not handling special characters**: HTML entities like `&nbsp;` between res and %

---

## Next Steps

1. Copy the debug scripts to your TitansWarPro directory
2. Capture a live cave HTML page
3. Run `debug_cave_html.sh` to analyze structure
4. Try improvement recommendations in order
5. Commit working pattern to git

