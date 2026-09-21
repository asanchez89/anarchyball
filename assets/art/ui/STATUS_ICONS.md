# NPC conflict status icons

Runtime atlas: `status_icons_16bit_v1.png`, six 32×32 cells in canonical
`ConflictStateComponent.State` order: neutral, disputed, threatening,
aggressor, surrendering, neutralized.

Generated with the built-in image generation tool, then deterministically
cropped and reduced with nearest-neighbor sampling by
`tools/art/curate_status_icon_sheet.ps1`.

Prompt summary: polished 16-bit sci-fi pixel icons compatible with Warped;
cyan hollow circle, violet question diamond, amber alert triangle, red crossed
energy bolts, green white flag, slate check; transparent background, no text.
