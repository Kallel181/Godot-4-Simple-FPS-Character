extends CharacterBody3D

#==========Internal==========
var gravity:float  = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed:float

const default_height: float = 1.0
const crouch_height:float = 0.70


#==========Exports==========
@export var mouse_sensitivity:float = 0.1
@export var lerp_move_weight:float = 0.2
@export var jump_height:float = 2.0
@export var walk_move_speed: float = 5.0
@export var crouch_move_speed: float = 2.0

#==========Nodes==========
#Variaveis do tipo NodePath precisam ser inicializadas pela interface da engine
@export var head_path : NodePath
@onready var head : Node3D = get_node(head_path)

@export var flass_light_path : NodePath
@onready var flass_light:SpotLight3D = get_node(flass_light_path)

@export var heard_ray_cast_path : NodePath
@onready var heard_ray_cast:RayCast3D = get_node(heard_ray_cast_path)





#==========Ready==========
func _ready() -> void:
	#por padrão ao iniciar o mouse fica capturado na tela do jogo
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#==========pProcess==========
func _physics_process(delta) -> void:
	apply_gravity(delta)
	move_player(delta)

#==========Input==========
func _input(event) -> void:
	camera(event) 
	lock_and_unlock_mouse(event)
	flash_light()





#Functions
func camera(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		#mantendo a rotação separada, y no corpo do personagem e x em um node separado que contem a camera
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		
		#mantem movimento da camera preso entre 90 e -90
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-90),deg_to_rad(90))


func move_player(delta):
	#Controle do pulo
	#Note que a função is_on_floor detecta se estamos pisando no chão, similarmente godot tambem apresenta
	#is_on_ceiling() e is_on_wall() sem a necessidade de tags ou grupos
	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = sqrt(jump_height * 2.0 * gravity)
	
	
	#Controle da velocidade caso apertarmos ctrl, ou seja, player esta agachado
	speed = walk_move_speed
	if not heard_ray_cast.is_colliding():
		scale.y = lerp(scale.y,default_height,0.1)
	if Input.is_action_pressed("ctrl"):
		speed = crouch_move_speed
		scale.y = lerp(scale.y,crouch_height-0.3,0.1)
	
	
	#h_rot armazena o valor da rotação em relação ao eixo y
	#A função get_euler retorna um valor, em radianos dessa rotação
	var h_rot = global_transform.basis.get_euler().y
	
	#input_dir armazena um valor do tipo Vector2 com as teclas pressionadas
	#note que temos x para o movimento lateral e y para o momento frontal
	#alem disso a coordenada x e/ou y será 0 se apressionarmos as teclas opostas ao mesmo tempo
	var input_dir = Input.get_vector("a", "d", "w", "s")
	
	#o vetor de direção será igual ao vetor do nosso imput rotacionado com o mesmo valor da rotação do eixo y
	#em seguida normalizamos a direção
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, h_rot).normalized()
	
	#ao passarmos direction apenas como condição, por padrão, godot interpreta como direction != Vector3.ZERO
	if direction:
		#interpolação linear leva de um certo valor inicial para um calor desejado atravez de um peso
		velocity.x = lerp(velocity.x,direction.x * speed, lerp_move_weight)
		velocity.z = lerp(velocity.z,direction.z * speed, lerp_move_weight)
	else:
		velocity.x = lerp(velocity.x, 0.0, lerp_move_weight)
		velocity.z = lerp(velocity.z, 0.0, lerp_move_weight)
	
	#A nova funçao move_and_slide automaticamente usa a variavel velocity, que agora, na versão 4, é uma 
	#variavel já reconhecida dentro da engine
	move_and_slide()


func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0


func lock_and_unlock_mouse(event:InputEvent):
	if event.is_action_pressed("esc"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func flash_light():
	if Input.is_action_just_pressed("f"):
		flass_light.visible = not flass_light.visible




