class_name UISkin
## Shared retro theme builder: BMFont pixel font, 9-slice panels, chunky buttons.

const FONT := "res://assets/fonts/pixel6x8.fnt"

static var _theme: Theme


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	var font: Font = load(FONT)
	if font == null:
		push_error("Pixel font missing!")
		return t
	t.default_font = font
	t.set_default_font_size(8)
	t.set_color("font_color", "Label", Color("f2f2f2"))
	# Deliberately no Label drop shadow: a 1px shadow at this size doubles
	# strokes and makes light-panel dialogue hard to read.

	var panel := StyleBoxTexture.new()
	panel.texture = load("res://assets/ui/panel.png")
	panel.texture_margin_left = 8
	panel.texture_margin_right = 8
	panel.texture_margin_top = 8
	panel.texture_margin_bottom = 8
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("normal", "PanelContainer", panel)

	var dark := StyleBoxTexture.new()
	dark.texture = load("res://assets/ui/panel_dark.png")
	dark.texture_margin_left = 8
	dark.texture_margin_right = 8
	dark.texture_margin_top = 8
	dark.texture_margin_bottom = 8

	var red := StyleBoxTexture.new()
	red.texture = load("res://assets/ui/panel_red.png")
	red.texture_margin_left = 8
	red.texture_margin_right = 8
	red.texture_margin_top = 8
	red.texture_margin_bottom = 8
	t.set_stylebox("panel", "PanelRed", red)
	t.set_stylebox("panel", "PanelDark", dark)

	var btn := StyleBoxTexture.new()
	btn.texture = load("res://assets/ui/button.png")
	btn.texture_margin_left = 6
	btn.texture_margin_right = 6
	btn.texture_margin_top = 6
	btn.texture_margin_bottom = 6
	t.set_stylebox("normal", "Button", btn)
	t.set_stylebox("hover", "Button", btn)
	t.set_stylebox("pressed", "Button", btn)
	t.set_color("font_color", "Button", Color("f2f2f2"))
	t.set_color("font_hover_color", "Button", Color("f7e94b"))
	t.set_font_size("font_size", "Button", 8)
	return t


## Build a simple texture-backed panel node.
static func make_panel(variant: String = "panel") -> Panel:
	var p := Panel.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/ui/%s.png" % variant)
	sb.texture_margin_left = 8
	sb.texture_margin_right = 8
	sb.texture_margin_top = 8
	sb.texture_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	return p


static func label(text: String, size := 8, color := Color("f2f2f2")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	# No drop shadow: at 8px, a 1px shadow doubles every stroke and destroys
	# legibility on light panels. The palette already has enough contrast.
	return l


static func nine_patch(tex_path: String, margin := 8) -> TextureRect:
	var tr := TextureRect.new()
	var tex := load(tex_path)
	tr.texture = tex
	tr.draw_center = true
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	return tr
