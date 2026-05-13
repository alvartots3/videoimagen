import bpy
import math
import random
import os

def clean_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def setup_camera():
    bpy.ops.object.camera_add(location=(7.35, -6.9, 4.9), rotation=(math.radians(63), 0, math.radians(46)))
    cam = bpy.context.object
    bpy.context.scene.camera = cam
    return cam

def setup_render(output_dir, resolution_x=1920, resolution_y=1080):
    bpy.context.scene.render.resolution_x = resolution_x
    bpy.context.scene.render.resolution_y = resolution_y
    bpy.context.scene.render.image_settings.file_format = 'PNG'
    base_path = r"C:\Users\crist\VideoImagen\proyectoVideo"
    out_path = os.path.join(base_path, output_dir)
    if not os.path.exists(out_path):
        os.makedirs(out_path, exist_ok=True)
    bpy.context.scene.render.filepath = os.path.join(out_path, "frame_")

def add_light(location=(0, 0, 5), energy=1000, type='POINT'):
    bpy.ops.object.light_add(type=type, location=location)
    light = bpy.context.object
    light.data.energy = energy
    return light

def render_sequence(sequence_name, num_frames=10):
    for f in range(1, num_frames + 1):
        bpy.context.scene.frame_set(f)
        # Update render path for each frame
        base_path = r"C:\Users\crist\VideoImagen\proyectoVideo"
        bpy.context.scene.render.filepath = os.path.join(base_path, sequence_name, f"frame_{f:04d}.png")
        bpy.ops.render.render(write_still=True)
