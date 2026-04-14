# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`emissary-names` is a Ruby gem that generates procedural fantasy place names by deriving syllable patterns and prefix/suffix frequencies from real-world source word lists. It is part of the Emissary turn-based strategy game monorepo.

## Commands

```bash
bundle install
bundle exec bin/emissary-names                          # generate 10 fantasy names (default)
bundle exec bin/emissary-names --culture=maritime       # generate names for a specific culture
bundle exec bin/emissary-names --culture=desert --number=20 --seed=42
```

Available cultures: `desert`, `arid`, `mountainous`, `forested`, `lowland`, `maritime`, `fantasy`

## Architecture

### Name generation pipeline

1. **Terrain → culture mapping** (`Names.get_culture_for_terrain`): Given a hash of terrain type → rating, applies `@@rules` to determine which culture matches based on percentage thresholds. Multiple cultures can match; the first is used.

2. **Source word analysis** (`NameUtils#get_data_for_words`): For non-fantasy cultures, the source word list (e.g. Welsh place names for `forested`, Norse for `mountainous`) is analysed to extract:
   - Prefixes/suffixes — multi-word names split on spaces; the longest part is the base word
   - Syllable decomposition into `starts`, `middles`, `ends` arrays
   - `syllable_lengths` frequency table (how many middle syllables source words tend to have)
   - Observed prefix/suffix frequencies (ratios used as probabilities)

3. **Name assembly** (`Names#get_name`): Randomly combines start + N middles (sampled using `syllable_lengths` frequency table) + end, optionally wraps with a prefix/suffix, then rejects any output that matches a source word.

4. **Fantasy fallback** (`NameSources.data_for_fantasy`): Uses a hand-curated list of Celtic/Germanic place-name components instead of deriving syllables from a source list. Middle syllables are disabled (length always 0).

### Key files

| File | Purpose |
|---|---|
| `lib/emissary-names.rb` | `Emissary::Names` — public API, terrain rules, name assembly |
| `lib/name_sources.rb` | `Emissary::NameSources` — source word lists per culture; fantasy component lists |
| `lib/name_utils.rb` | `Emissary::NameUtils` — syllable splitting, prefix/suffix extraction, frequency helpers |
| `bin/emissary-names` | CLI wrapper with `--culture`, `--number`, `--seed` options |

### Family name generation

`get_family_name` uses three strategies:

- **~10% chance (all cultures):** calls `get_name` and appends a culture suffix (e.g. `-er`, `-wyn`, `-i`) to derive a place-origin name.
- **Lowland:** combines random elements from `NameSources::LOWLAND_FAMILY_FIRSTS` and `LOWLAND_FAMILY_SECONDS` (e.g. *Falkenberg*, *Rosenrath*).
- **All others:** picks a start + end syllable pair and optionally prepends a culture particle from `Names::PARTICLES` (e.g. *von Bergholt*, *ap Llanwick*, *al-Perseph*).

Both `get_name` and `get_family_name` track generated names in per-type `Set`s on the instance, so repeated calls on the same instance will not return duplicates.

### Adding a new culture

1. Add source words as a `@@culture_name` class variable in `NameSources`, and expose it via `for_culture`.
2. Add a terrain rule entry in `Names::@@rules` mapping the culture symbol to terrain percentage ranges.
3. Add an entry to `Names::PARTICLES` and `Names::PLACE_SUFFIXES` for the new culture.
