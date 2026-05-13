import bpy
import random
import ScriptBase
from escena1 import create_random_objects

# Generate 3 sequences for Escena 3: Contraluz y Cenital
for seq in range(1, 4):
    ScriptBase.clean_scene()
    ScriptBase.setup_camera()
    ScriptBase.setup_render(f"escena3_{seq}")
    
    # Randomly choose backlight or zenith
    if random.choice([True, False]):
        # Contraluz (Light behind objects, facing camera)
        ScriptBase.add_light(location=(0, 5, 2), energy=3000)
    else:
        # Cenital (Light directly above)
        ScriptBase.add_light(location=(0, 0, 8), energy=3000)
        
    objs = create_random_objects(random.randint(4, 7))
    
    for obj in objs:
        obj.rotation_euler = (random.uniform(0, 3.14), random.uniform(0, 3.14), random.uniform(0, 3.14))
        obj.keyframe_insert(data_path="rotation_euler", frame=1)
        obj.rotation_euler[2] += 1.5
        obj.keyframe_insert(data_path="rotation_euler", frame=10)
        
    ScriptBase.render_sequence(f"escena3_{seq}", num_frames=10)

print("Escena 3 completada")
