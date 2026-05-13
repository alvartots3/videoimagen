import bpy
import random
import ScriptBase
from escena1 import create_random_objects

# Generate 3 sequences for Escena 2: Luz móvil
for seq in range(1, 4):
    ScriptBase.clean_scene()
    ScriptBase.setup_camera()
    ScriptBase.setup_render(f"escena2_{seq}")
    
    # Create moving light
    light = ScriptBase.add_light(location=(-5, -5, 5), energy=3000)
    
    # Random objects (static or slight rotation)
    objs = create_random_objects(random.randint(4, 7))
    
    # Animate light
    light.location = (-5, -5, 5)
    light.keyframe_insert(data_path="location", frame=1)
    
    light.location = (5, 5, 5)
    light.keyframe_insert(data_path="location", frame=10)
        
    ScriptBase.render_sequence(f"escena2_{seq}", num_frames=10)

print("Escena 2 completada")
