# Sekala Boutique

A 2D chibi dress-up game built in **Godot 4.7** (`1280×720`).

Players greet Alya in the boutique dialogue scene and then dress her using the wooden wardrobe in `scenes/dress_up_page.tscn`.

---

## Project Structure

```text
.
├── project.godot
├── scenes/
│   ├── dialogue_page.tscn        # Intro dialogue scene (main scene)
│   └── dress_up_page.tscn        # Dress-up & wardrobe scene
├── scripts/
│   ├── dialogue_page.gd
│   └── dress_up_page.gd          # Dynamic wardrobe, pagination & outfit/accessory config
└── assets/
    ├── backgrounds/              # Room & boutique backgrounds
    ├── characters/
    │   ├── Alya/                 # Base chibi Alya.png (1536x2048) & portrait
    │   └── Sekala/
    ├── ui/                       # Category button icons (Top, Bottom, Outer, Accessories)
    └── outfits/
        ├── Top/
        ├── Bottom/
        ├── Outer/
        └── Accessories/          # Strict naming rule required (see below)
```

---

## How to Run

1. Open the project folder in **Godot 4.7+**.
2. Press **F5** to run from the intro dialogue (`scenes/dialogue_page.tscn`), or press **F6** on `scenes/dress_up_page.tscn` to test the dress-up screen directly.

---

## How to Add More Clothes to the Wardrobe

The wardrobe loads images **dynamically** from the folders inside `assets/outfits/`. You do not need to manually edit `dress_up_page.tscn` when adding new items.

1. Export your artwork as a transparent `.png` (`.webp`, `.jpg`, and `.jpeg` are also supported).
2. Drop the file into the matching category folder:
   - `assets/outfits/Top/`
   - `assets/outfits/Bottom/`
   - `assets/outfits/Outer/`
   - `assets/outfits/Accessories/`
3. Open the project in Godot so the editor imports the new image (or run directly).
4. The item appears automatically in that category's right-side wardrobe shelf.
   - Wardrobe thumbnails are **auto-cropped** to visible pixels, so even small items drawn on a full `1536×2048` canvas display clearly inside each slot.
   - Each wardrobe page holds **8 slots** (2×4). Once a category folder has **more than 8 images**, the `< 1 / 2 >` pagination controls appear automatically at the bottom of the wardrobe.

---

## File Naming Rules

### 1. Accessories (`assets/outfits/Accessories/`) — STRICT RULE

Accessories cover many different body parts (shoes, ribbons, hats, glasses, rings, etc.). To assign each PNG to the correct body location, layer order, and equipment slot automatically, **every file in `assets/outfits/Accessories/` must follow this exact format**:

```text
<type>_<item_name>.png
```

- `<type>` must be one of the configured lowercase prefixes listed in the table below.
- `_` (underscore) separates the type from the item name.
- `<item_name>` must be non-empty (lowercase letters, numbers, and underscores recommended, e.g., `ribbon_pink_bow.png`).
- **Files that do not match `<type>_<item_name>.png` are skipped** and logged as a warning in the Godot Output console.

#### Configured Accessory Types & Positions

| Prefix (`<type>`) | Body Location | Anchor (`x, y`) | `z_index` | Example Filenames |
| :--- | :--- | :---: | :---: | :--- |
| `shoes` | Feet (drawn under skirts) | `(410, 533)` | `0` | `shoes_white.png`, `shoes_mary_jane.png` |
| `ribbon` | Hair side ribbon / bow | `(462, 198)` | `8` | `ribbon_bow.png`, `ribbon_gold.png` |
| `hat` | Top of head | `(398, 168)` | `9` | `hat_beret.png`, `hat_sunhat.png` |
| `glasses` | Eyes / face | `(392, 248)` | `7` | `glasses_round.png`, `glasses_cat_eye.png` |
| `earring` | Visible ear | `(460, 264)` | `6` | `earring_pearl.png`, `earring_drop.png` |
| `necklace` | Neck / collarbone | `(412, 322)` | `4` | `necklace_pearl.png`, `necklace_choker.png` |
| `armband` | Arm / sleeve band | `(468, 374)` | `5` | `armband_gold.png`, `armband_ribbon.png` |
| `glove` | Hands | `(419, 422)` | `5` | `glove_lace.png`, `glove_white.png` |
| `ring` | Open hand fingers | `(498, 420)` | `6` | `ring_gold.png`, `ring_diamond.png` |

#### Valid vs. Invalid Accessory Names

- **Valid:** `shoes_white.png`, `ribbon_bow.png`, `hat_straw_sunhat.png`, `glasses_round.png`, `ring_emerald.png`
- **Invalid (skipped):** `White shoes.png`, `Bow access.png`, `shoes.png`, `crown_gold.png` (until `crown` is added to `CONFIG["accessory_slots"]`)

#### Slot Behavior for Accessories

- Alya can wear **different accessory types at the same time** (for example: `shoes_white.png` + `ribbon_bow.png` + `glasses_round.png` + `necklace_pearl.png` + `ring_gold.png`).
- Equipping a second item with the **same `<type>`** replaces the previous item of that type (for example, clicking `shoes_red.png` replaces `shoes_white.png`).
- Clicking an already-equipped item unequips it.

---

### 2. Tops, Bottoms, and Outers (`Top/`, `Bottom/`, `Outer/`)

These categories load any valid image file in their folder, and only one item per category can be worn at a time.

Recommended naming convention (keeps sorting clean and readable):

```text
<category>_<item_name>.png
```

Examples:
- `assets/outfits/Top/top_kebaya_pink.png`
- `assets/outfits/Bottom/bottom_floral_skirt.png`
- `assets/outfits/Outer/outer_cream_cardigan.png`

---

## Art Sizing & Alignment Guidelines

Two art workflows are supported automatically:

1. **Full-Canvas Overlay (`1536×2048` — recommended for Tops, Bottoms, Outers, and multi-part accessories like Shoes or Gloves):**
   - Draw the garment directly over `assets/characters/Alya/Base chibi Alya.png` (`1536×2048`) and export the layer with transparent background at the exact same `1536×2048` dimensions.
   - The script detects the `1536×2048` size and aligns the sprite directly to `BaseCharacter`.
2. **Cropped Standalone PNG (supported for Accessories):**
   - Export only the accessory itself (cropped tightly with transparent background, e.g., `glasses_round.png` or `ring_gold.png`).
   - Because the size differs from `1536×2048`, the script automatically places the sprite at the pre-configured `position`, `scale`, and `z_index` defined for its `<type>` in `CONFIG["accessory_slots"]`.

---

## Configuring Accessory Positions & Adding New Types

All accessory anchor locations live in one place: `CONFIG["accessory_slots"]` at the top of `scripts/dress_up_page.gd`.

To add a new accessory type (for example `bag`):

1. Open `scripts/dress_up_page.gd`.
2. Add a new entry inside `CONFIG["accessory_slots"]`:
   ```gdscript
   "bag": {
       "position": Vector2(335, 445),
       "scale": Vector2(0.214, 0.214),
       "z_index": 6,
       "under_clothes": false,
   },
   ```
3. Add PNG files named `bag_<item_name>.png` into `assets/outfits/Accessories/`.

---

## Replacing Category Button Icons

The four left-side wardrobe category buttons use temporary placeholder PNGs stored in `assets/ui/`:

- `assets/ui/Top.png`
- `assets/ui/Bottom.png`
- `assets/ui/Outer.png`
- `assets/ui/Accessories.png`

Replace any of these files with final artwork using the same filename (`164×180` aspect ratio fits the wooden cubbies cleanly).
