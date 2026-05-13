import bpy
import random
import ScriptBase

def create_colored_objects(num_objects=5):
    objects = []
    types = ['CUBE', 'CYLINDER', 'SPHERE', 'CONE', 'TORUS', 'MONKEY']
    
    for _ in range(num_objects):
        obj_type = random.choice(types)
        loc = (random.uniform(-4, 4), random.uniform(-4, 4), random.uniform(0.5, 2))
        scale = random.uniform(0.5, 1.2)
        
        if obj_type == 'CUBE':
            bpy.ops.mesh.primitive_cube_add(location=loc)
        elif obj_type == 'CYLINDER':
            bpy.ops.mesh.primitive_cylinder_add(location=loc)
        elif obj_type == 'SPHERE':
            bpy.ops.mesh.primitive_uv_sphere_add(location=loc)
        elif obj_type == 'CONE':
            bpy.ops.mesh.primitive_cone_add(location=loc)
        elif obj_type == 'TORUS':
            bpy.ops.mesh.primitive_torus_add(location=loc)
        elif obj_type == 'MONKEY':
            bpy.ops.mesh.primitive_monkey_add(location=loc)
            
        obj = bpy.context.object
        obj.scale = (scale, scale, scale)
        
        # Random Color Material
        mat = bpy.data.materials.new(name="RandomColor")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs['Base Color'].default_value = (random.random(), random.random(), random.random(), 1.0)
        
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)
            
        objects.append(obj)
    return objects

# Generate 3 sequences for Escena 4: Colores
for seq in range(1, 4):
    ScriptBase.clean_scene()
    ScriptBase.setup_camera()
    ScriptBase.setup_render(f"escena4_{seq}")
    ScriptBase.add_light(location=(0,0,6), energy=2000)
    
    objs = create_colored_objects(random.randint(4, 7))
    
    for obj in objs:
        obj.rotation_euler = (random.uniform(0, 3.14), random.uniform(0, 3.14), random.uniform(0, 3.14))
        obj.keyframe_insert(data_path="rotation_euler", frame=1)
        obj.rotation_euler[2] += 1.5
        obj.keyframe_insert(data_path="rotation_euler", frame=10)
        
    ScriptBase.render_sequence(f"escena4_{seq}", num_frames=10)

print("Escena 4 completada")
