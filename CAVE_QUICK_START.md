# Quick Start: Cave Resources Extraction Debug

## The Problem (in 30 seconds)

Your `_cave_display_probabilities()` function uses this grep pattern that doesn't work:

```bash
grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%'
```

**Result**: "Recursos encontrados" displays but resources/percentages are blank.

---

## The Fix (Try This First!)

Edit `/c/Users/hugov/OneDrive/Documentos/GitHub/TitansWarPro/cave.sh` line 145:

**CHANGE THIS:**
```bash
grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$TMP/SRC" | while read -r match; do
```

**TO THIS:**
```bash
grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC" | while read -r match; do
```

**Why**: The HTML between resource image and percentage contains `<` and `>` characters which break the old pattern. The new pattern matches "up to the next `<` tag" which is more reliable.

---

## If That Doesn't Work...

I've created **3 interactive debugging tools**:

### 1. Quick Test Interactive Menu
```bash
./test_cave_patterns.sh /path/to/cave_src_file
```
Then try options 4, 5, 6 to test different patterns.

### 2. Full Analysis Script
```bash
./debug_cave_html.sh /path/to/cave_src_file
```
Shows 10 different analysis patterns to understand HTML structure.

### 3. Strategy Analyzer
```bash
./debug_cave_patterns.sh /path/to/cave_src_file
```
Tests 7 different extraction strategies.

---

## How to Get a Cave HTML File for Testing

```bash
# Set up your account
export ACCOUNT_ID="A1"
source /path/to/requeriments.sh

# Source info.sh (provides fetch_page function)
source /path/to/info.sh

# Fetch a cave page
fetch_page "/cave/"

# Now analyze it
./test_cave_patterns.sh "$TMP/SRC"
```

---

## Pattern Comparison

| Pattern | Type | Use When |
|---------|------|----------|
| `[^%]{0,100}?` (current) | Stop at % | **BROKEN - don't use** |
| `[^<]*` (quick fix) | Stop at tag | Resources near percentages |
| `[^>]*` | Stop at > | Resources in HTML attributes |
| `.{0,50}res.*%.{0,50}` | Context | Large whitespace between |

---

## Where Are the Tools?

All files created in: `/c/Users/hugov/OneDrive/Documentos/GitHub/TitansWarPro/`

- **`debug_cave_html.sh`** - 10 pattern test analysis (4.6 KB)
- **`debug_cave_patterns.sh`** - 7 strategy-based tests (4.0 KB)
- **`test_cave_patterns.sh`** - Interactive menu tester (6.9 KB)
- **`CAVE_DEBUG_GUIDE.md`** - Detailed explanation (7.9 KB)
- **`CAVE_SOLUTIONS.md`** - Problem analysis & fixes (8.2 KB)

---

## Quick Diagnostic Commands

```bash
# Check if resources exist in HTML
grep -c 'res/' "$TMP/SRC"

# Check if percentages exist
grep -c '%' "$TMP/SRC"

# Test current (broken) pattern
grep -oE 'res/[0-9]+\.png[^%]{0,100}?[0-9]+%' "$TMP/SRC" | wc -l

# Test quick fix pattern
grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC" | wc -l
```

If the last command shows `> 0`, the quick fix works!

---

## Expected Output After Fix

**Before fix:**
```
💎 Resources found
(nothing shows here - blank)
```

**After fix:**
```
💎 Resources found
  Iron (45%)
  Silver Ore (38%)
  Crystal (12%)
  Herb (5%)
```

---

## Next Steps

1. **Try the quick fix first** (change line 145 as shown above)
2. **If that works**, commit it: `git add cave.sh && git commit -m "fix: cave resource extraction pattern"`
3. **If it doesn't work**, run `./test_cave_patterns.sh` to find which pattern works
4. **Use option 9** in the interactive tester to test custom patterns

---

## HTML Structure (What's Happening)

The issue is that `w3m -dump_source` returns raw HTML with tags:

```html
<!-- Example HTML structure -->
<div class="resource">
  <img src="res/1.png"/>
  <br/>                        <!-- <-- This breaks the old pattern! -->
  <span>Iron</span>
  <span class="pct">45%</span>
</div>
```

The old pattern tries to go from `res/1.png` to `45%` without hitting `%` chars, but it fails when there's a `<br/>` tag in between (because the pattern is looking for `[^%]` which includes `<` and `>`, but then the pattern stops matching when the actual `%` is further away).

The new pattern with `[^<]*` says "match everything up to the next `<` tag", which works with any HTML structure.

---

## Debugging Matrix

| Check | Command | Expected | If 0 = |
|-------|---------|----------|--------|
| Resources in HTML? | `grep -c 'res/' "$TMP/SRC"` | `> 0` | Cave page didn't load |
| Percentages in HTML? | `grep -c '%' "$TMP/SRC"` | `> 0` | No percentage data |
| Current pattern works? | `grep ...current... \| wc -l` | `0` | Confirms it's broken |
| Fix pattern works? | `grep ...fixed... \| wc -l` | `> 0` | Quick fix works! |

---

## Contact/Issues

If none of the patterns work:

1. Run: `grep -n 'res/' "$TMP/SRC" | head -5`
2. Show the output - it will reveal the HTML structure
3. The structure will immediately show what pattern is needed

The problem is definitely solvable with one of the provided patterns or a variation.

