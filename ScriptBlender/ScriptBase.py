import bpy
import math
import random
from mathutils import Vector
from datetime import datetime
import os

# --------------------------------------------------
# LIMPIAR ESCENA
# --------------------------------------------------
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene

# --------------------------------------------------
# CONFIGURACIÓN
# --------------------------------------------------
# Modifica esta ruta para que apunte a la carpeta donde quieres guardar los frames
output_folder = "./Video"   

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
output_folder = f"{output_folder}/escena1_{timestamp}/"
os.makedirs(output_folder, exist_ok=True)

# --------------------------------------------------
# PARÁMETROS DE ANIMACIÓN
# --------------------------------------------------
scene.frame_start = 1
scene.frame_end = 10  # Mantengo 10 frames para pruebas rápidas. Súbelo a 24 o 48 para el render final
scene.render.fps = 24
scene.render.resolution_x = 720
scene.render.resolution_y = 720

distance = 25.0
num_frames = scene.frame_end - scene.frame_start + 1

# --------------------------------------------------
# SUELO Y MATERIALES
# --------------------------------------------------
bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
ground = bpy.context.object

def create_material(name, color):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    return mat

mat_white = create_material("White", (1, 1, 1))
ground.data.materials.append(mat_white)

# --------------------------------------------------
# GENERACIÓN ALEATORIA DE OBJETOS
# --------------------------------------------------
# Definimos los metodos de creacion de primitivas de Blender
def add_cube(loc, scale): bpy.ops.mesh.primitive_cube_add(location=loc, scale=scale)
def add_cylinder(loc, scale): bpy.ops.mesh.primitive_cylinder_add(location=loc, scale=scale)
def add_sphere(loc, scale): bpy.ops.mesh.primitive_uv_sphere_add(location=loc, scale=scale)
def add_cone(loc, scale): bpy.ops.mesh.primitive_cone_add(location=loc, scale=scale)
def add_torus(loc, scale): bpy.ops.mesh.primitive_torus_add(location=loc) # Torus maneja la escala diferente
def add_monkey(loc, scale): bpy.ops.mesh.primitive_monkey_add(location=loc, scale=scale)

# Clasificamos teoricamente los objetos para asegurar variedad
shapes = [add_cube, add_cylinder, add_sphere, add_cone, add_torus, add_monkey]

num_objects = 10 # Cantidad de objetos a generar por escena

for i in range(num_objects):
    # Generamos coordenadas (x,y) aleatorias dentro de un limite para no salir de camara
    rand_x = random.uniform(-8, 8)
    rand_y = random.uniform(-8, 8)
    
    # Escala aleatoria uniforme
    rand_scale = random.uniform(0.5, 1.5)
    
    # Z se ajusta segun la escala para que descansen sobre el plano (suelo en Z=0)
    rand_z = rand_scale 
    
    # Seleccionamos una forma aleatoria
    shape_func = random.choice(shapes)
    
    loc = (rand_x, rand_y, rand_z)
    scale = (rand_scale, rand_scale, rand_scale)
    
    # Instanciamos la forma
    shape_func(loc, scale)
    obj = bpy.context.object
    
    # En el caso del toroide, forzamos la escala a posteriori
    if shape_func == add_torus:
        obj.scale = scale
        
    obj.data.materials.append(mat_white)

# --------------------------------------------------
# LUZ TIPO SUN Y CÁMARA
# --------------------------------------------------
bpy.ops.object.light_add(type='SUN', location=(0, 0, distance))
sun = bpy.context.object
sun.data.energy = 3.5

bpy.ops.object.camera_add(location=(0, 0, distance))
cam = bpy.context.object
cam.name = "OrbitCamera"
cam.data.lens = 50
scene.camera = cam

target = bpy.data.objects.new("CamTarget", None)
target.location = (0, 0, 0)
bpy.context.collection.objects.link(target)

constraint = cam.constraints.new(type='TRACK_TO')
constraint.target = target
constraint.track_axis = 'TRACK_NEGATIVE_Z'
constraint.up_axis = 'UP_Y'

# --------------------------------------------------
# ANIMACIÓN LINEAL Y RENDER
# --------------------------------------------------
for i, frame in enumerate(range(scene.frame_start, scene.frame_end + 1)):
    t = i / (num_frames - 1)
    theta = (math.pi / 2) * (1 - t)
    x = distance * math.cos(theta)
    y = 0.0
    z = distance * math.sin(theta)

    cam.location = (x, y, z)
    cam.keyframe_insert(data_path="location", frame=frame)

if cam.animation_data and cam.animation_data.action:
    action = cam.animation_data.action
    if hasattr(action, "fcurves"):
        for fcurve in action.fcurves:
            for kp in fcurve.keyframe_points:
                kp.interpolation = 'LINEAR'

scene.render.filepath = output_folder
scene.render.image_settings.file_format = 'PNG'

# Descomentar para renderizar la animacion al ejecutar
bpy.ops.render.render(animation=True)