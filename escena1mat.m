% escena1mat.m
% Script para procesar la Escena 1 mediante análisis de sombras

% 1. Configuración de rutas (Ajusta el nombre de la carpeta final)
input_folder = 'C:\Users\crist\VideoImagen\Video\escena1_AQUI_LA_FECHA'; 
output_video_path = 'C:\Users\crist\VideoImagen\Video\escena1_salida.mp4';

% Obtener todos los frames PNG
image_files = dir(fullfile(input_folder, '*.png'));
num_frames = length(image_files);

% Preparar el escritor de video
v = VideoWriter(output_video_path, 'MPEG-4');
v.FrameRate = 24; % Mantener la coherencia con Blender
open(v);

% 2. Procesamiento lineal fotograma a fotograma
for k = 1:num_frames
    
    % Lectura
    img_path = fullfile(input_folder, image_files(k).name);
    I_rgb = imread(img_path);
    
    % Conversión a escala de grises
    I_gray = rgb2gray(I_rgb);

    % Calculo de umbral global de Otsu
    T = graythresh(I_gray);
    
    % Binarización invertida: buscamos los pixeles MÁS OSCUROS que el umbral
    % (las sombras)
    BW = imbinarize(I_gray, T); 
    BW_sombras = ~BW; 

    % Limpieza de ruido: eliminar pequeñas imperfecciones menores a 50 píxeles
    BW_limpia = bwareaopen(BW_sombras, 50);

    % Extracción de componentes conexas
    cc = bwconncomp(BW_limpia);
    
    % Cálculo de descriptores
    stats = regionprops(cc, 'Area', 'Centroid', 'BoundingBox', 'Extent', 'Solidity');

    % Preparar la imagen de salida para anotaciones
    I_out = I_rgb;

    % 3. Clasificación e iteración sobre los objetos encontrados
    for i = 1:cc.NumObjects
        
        % Filtramos sombras demasiado pequeñas para ser un objeto válido
        if stats(i).Area > 150
            
            bbox = stats(i).BoundingBox;
            centroid = stats(i).Centroid;
            solidity = stats(i).Solidity;
            
            % LÓGICA DE CLASIFICACIÓN (Afinable)
            % Figuras sólidas (cubos, esferas, cilindros) proyectan sombras densas.
            % Figuras complejas (monkey, torus) proyectan sombras con huecos.
            if solidity > 0.85
                label = '2D / Solido';
                color = 'green';
            else
                label = '3D / Complejo';
                color = 'red';
            end
            
            % Dibujar rectángulo y texto
            I_out = insertShape(I_out, 'Rectangle', bbox, 'Color', color, 'LineWidth', 2);
            I_out = insertText(I_out, centroid, label, 'BoxOpacity', 0.8, 'TextColor', 'white');
        end
    end

    % Guardar el fotograma procesado en el video
    writeVideo(v, I_out);
end

% Cerrar y guardar el archivo de video
close(v);
disp('Procesamiento completado. Revisa el archivo escena1_salida.mp4');