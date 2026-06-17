extends PanelContainer

@onready var btn_nuevo = $HBoxContainer/BtnNuevo
@onready var btn_guardar = $HBoxContainer/BtnGuardar
@onready var btn_cargar = $HBoxContainer/BtnCargar
@onready var btn_exportar = $HBoxContainer/BtnExportar
@onready var btn_pincel = $HBoxContainer/BtnPincel
@onready var btn_linea = $HBoxContainer/BtnLinea
@onready var btn_plano = $HBoxContainer/BtnPlano
@onready var btn_cubo = $HBoxContainer/BtnCubo
@onready var btn_esfera = $HBoxContainer/BtnEsfera
@onready var btn_triangulo = $HBoxContainer/BtnTriangulo
@onready var btn_hueco = $HBoxContainer/BtnHueco
@onready var btn_deshacer = $HBoxContainer/BtnDeshacer
@onready var btn_rehacer = $HBoxContainer/BtnRehacer

signal nuevo_presionado
signal guardar_presionado
signal cargar_presionado
signal exportar_presionado
signal herramienta_cambiada(herramienta: String)
signal hueco_cambiado(hueco: bool)
signal deshacer_presionado
signal rehacer_presionado

var herramienta_actual: String = "pincel"
var herramientas: Array = ["pincel", "linea", "plano", "cubo", "esfera", "triangulo"]

func _ready():
	btn_nuevo.pressed.connect(func(): emit_signal("nuevo_presionado"))
	btn_guardar.pressed.connect(func(): emit_signal("guardar_presionado"))
	btn_cargar.pressed.connect(func(): emit_signal("cargar_presionado"))
	btn_exportar.pressed.connect(func(): emit_signal("exportar_presionado"))
	btn_deshacer.pressed.connect(func(): emit_signal("deshacer_presionado"))
	btn_rehacer.pressed.connect(func(): emit_signal("rehacer_presionado"))
	
	btn_pincel.pressed.connect(func(): _set_herramienta("pincel"))
	btn_linea.pressed.connect(func(): _set_herramienta("linea"))
	btn_plano.pressed.connect(func(): _set_herramienta("plano"))
	btn_cubo.pressed.connect(func(): _set_herramienta("cubo"))
	btn_esfera.pressed.connect(func(): _set_herramienta("esfera"))
	btn_triangulo.pressed.connect(func(): _set_herramienta("triangulo"))
	btn_hueco.toggled.connect(_on_hueco_toggled)
	
	# Pincel activo por defecto
	btn_pincel.button_pressed = true

func _set_herramienta(herramienta: String):
	herramienta_actual = herramienta
	
	# Desactivar todos los botones de herramienta
	btn_pincel.button_pressed = herramienta == "pincel"
	btn_linea.button_pressed = herramienta == "linea"
	btn_plano.button_pressed = herramienta == "plano"
	btn_cubo.button_pressed = herramienta == "cubo"
	btn_esfera.button_pressed = herramienta == "esfera"
	btn_triangulo.button_pressed = herramienta == "triangulo"
	
	emit_signal("herramienta_cambiada", herramienta)
	print("Herramienta: ", herramienta)

func _on_hueco_toggled(pressed: bool):
	print("Botón hueco presionado: ", pressed)
	emit_signal("hueco_cambiado", pressed)
