---
name: writing-recipes
description: Use when creating recipe files from URLs or other sources, formatting recipes in markdown with specific ingredient syntax
---

# Writing Recipes

## Overview
Format recipes in markdown following specific conventions for tags, ingredient lists with semicolon separators, and terse instructions.

## When to Use
- User asks to create a recipe from a URL
- User wants to convert a recipe to their format
- User mentions "recipe format" or references existing recipe files

## Recipe Structure

```markdown
# Recipe Title

Tags: `Recipe`, `Cooking`, `[Cuisine]`, `[Type]`, `[Dish]`

[SOURCE_URL]

| Serves  | Prep  | Time  |
| --------|-------|-------|
| 4       | 20m   | 30m   |

## Ingredients
- Ingredient, Type; preparation notes (amount)
- Simple Ingredient (amount)

## Instructions
1. Terse instruction with Capitalized ingredients
2. Next step

## Notes
Optional notes section
```

## Ingredient Format Rules

**CRITICAL:** Ingredients use semicolon separators, NOT commas in descriptions:

```markdown
# ✅ CORRECT
- Chicken, Thighs; leave skin on (4)
- Oil, Olive (4tbsp)
- Onion, Brown; diced (1cup)
- Garlic; crushed (2-3 cloves)
- Tomatoes, San Marzano; blended (1can, 28oz)

# ❌ WRONG
- Guanciale (8 oz)
- Pecorino Romano, finely grated (2 oz)
- Black pepper, freshly ground (1 tsp)
```

**Pattern:**
- `Ingredient Name (amount)` - for simple items with no type or preparation
  - Example: `Sake (.25 cups)`, `Salt (to taste)`
- `Ingredient, Type (amount)` - when specifying variety/type WITHOUT preparation
  - Example: `Oil, Canola (.25 cups)`, `Dashi, Ichiban (2 cups)`
- `Ingredient, Type; preparation (amount)` - when specifying variety AND preparation
  - Example: `Chicken, Thighs; leave skin on (4)`, `Pepper, Black; freshly ground (to taste)`
- `Ingredient; preparation (amount)` - when only preparation needed, no type
  - Example: `Garlic; crushed (2-3 cloves)`, `Ginger; peeled and grated (1")`

**Order:** Ingredient first, then Type/Variety (comma), then preparation (semicolon)

**Measurements:**
- **Convert imperial to metric** for weights and large volumes:
  - oz → g (ounces to grams)
  - lb → g or kg (pounds to grams/kilograms)
  - fluid oz → ml (for liquids)
- **Keep imperial** for small measurements: teaspoon (tsp), tablespoon (tbsp), cup
- **No spaces:** `8oz` not `8 oz`, `4tbsp` not `4 tbsp`
- **Decimals for fractions:** `.25 cups` not `1/4 cups`

**Common conversions:**
- 1 lb = 450g
- 8 oz = 225g
- 16 oz = 450g
- 1 cup flour ≈ 120-130g (depends on ingredient)

## File Naming

`recipe-[cuisine]-[category]-[dish_name].md`

Examples:
- `recipe-italian-pasta-spaghetti_alla_puttanesca.md`
- `recipe-japanese-main-dashi_braised_chicken.md`
- `recipe-modern-salad-carrot_avocado.md`

## Table Headers

**Use exactly:** `Serves | Prep | Time`

NOT `Cook` or `Total` - third column is always `Time`

## Instructions Style

Keep terse, capitalize ingredient names:

```markdown
# ✅ CORRECT
1. Soften Onion with Oil and Salt over medium heat until soft; stir in Garlic, 1m
2. Add Chili, Tomatoes and Water from rinsing can, simmer medium-low heat 45-60m

# ❌ WRONG - too verbose
1. Prepare the guanciale by slicing into ¼-inch-thick pieces, then cut into roughly ½ x 1-inch pieces. Freezing for 10 minutes beforehand makes this easier.
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using commas in ingredient prep | Use semicolons: "Chicken, Thighs; skin on" |
| "Cook" column header | Use "Time" |
| Spaces in measurements | `8oz` not `8 oz` |
| Verbose instructions | Make terse, capitalize ingredients |
| Lowercase ingredients in instructions | Capitalize: "add Garlic" not "add garlic" |
| Using #### headers | Use ## for Ingredients, Instructions, Notes |
| Missing title | Always start with # Recipe Title |
| Wrong ingredient order | Ingredient, Type; preparation - not Type, Ingredient |
| Fractions in measurements | Use decimals: `.25 cups` not `1/4 cups` or `.33 cups` |

## Example Recipe

```markdown
# Dashi Braised Chicken

Tags: `Recipe`, `Cooking`, `Japanese`, `Dinner`, `Chicken`

| Serves  | Prep  | Time  |
| --------|-------|-------|
| 4       | 20m   | 30m   |

## Ingredients
- Chicken, Thighs; leave skin on (4)
- Sake (.25 cups)
- Soy Sauce (.25 cups)
- Oil, Canola (.25 cups)
- Onion, Yellow; cut into 1" strips (1)
- Mushrooms, Shiitake; remove stems (8)
- Turnips; peeled, cut into 1" strips (2)
- Scallions; half minced, half thinly angle sliced (4)
- Ginger; peeled and grated (1")
- Dashi, Ichiban (2 cups)

## Instructions
1. To marinade: rub Chicken with half the Sake and Soy Sauce in a bowl, cover and chill 30m
2. Fry Chicken (both sides) in Oil over medium-high heat until browned, 10m; remove and set aside with juices
3. Add Onion and fry until soft, 8m; Add Mushrooms, Turnips, Potatoes, and Carrot, cook until tender 15m
```
