extends Label

@export var letter_speed := 0.04
@export var line_delay := 0.35
@export var start_delay := 0.5
@export var max_visible_lines := 5

var boot_lines := [
	"BOOTING PROGRAMA SYSTEM...",
	"CHECKING MEMORY CORE...",
	"POWER GRID: OFFLINE",
	"LOGIC MODULE: STANDBY",
	"PLANET STATUS: LIFE SUPPORT LOST",
	"ROBOT UNIT E-LIS: ACTIVE",
	"AWAITING RESTORE COMMAND..."
]

var visible_lines := []


func _ready():
	text = ""
	start_boot_text()


func start_boot_text():
	await get_tree().create_timer(start_delay).timeout

	for line in boot_lines:
		await type_line(line)
		await get_tree().create_timer(line_delay).timeout


func type_line(line: String):
	visible_lines.append("")

	if visible_lines.size() > max_visible_lines:
		visible_lines.pop_front()

	for i in line.length():
		visible_lines[visible_lines.size() - 1] += line[i]
		text = "\n".join(visible_lines)
		await get_tree().create_timer(letter_speed).timeout
