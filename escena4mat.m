% escena4_tracking.m
% Arquitectura: Segmentación HSV + Tracking Temporal + Topología (Euler)

% 1. Configuración de rutas exacta
ruta_base = 'C:\Users\crist\VideoImagen\proyectoVideo';
nombre_escena = 'escena4_20260515_103853'; 
carpeta_entrada = fullfile(ruta_base, nombre_escena);
carpeta_salida = fullfile(ruta_base, [nombre_escena, '_salida']);

if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

archivos = dir(fullfile(carpeta_entrada, '*.png'));

if isempty(archivos)
    error('No se han encontrado fotos en: %s', carpeta_entrada);
end

% Configurar video de salida
v = VideoWriter(fullfile(ruta_base, 'escena4_tracking_video.mp4'), 'MPEG-4');
v.FrameRate = 12;
open(v);

fprintf('Procesando %d fotogramas con Tracking...\n', length(archivos));

% TRACKING: Memoria del fotograma anterior
objetos_memoria = []; 

for f = 1:length(archivos)
    nombre_archivo = archivos(f).name;
    ruta_completa = fullfile(carpeta_entrada, nombre_archivo);
    
    imagenO = imread(ruta_completa);
    
    % =========================================================
    % 1. PREPROCESADO: SEGMENTACIÓN CROMÁTICA HSV MEJORADA
    % =========================================================
    I_hsv = rgb2hsv(imagenO);
    Saturation = I_hsv(:,:,2); 
    
    % Binarizamos por saturación (elimina suelo blanco y sombras)
    BW_color = Saturation > 0.25;
    
    % 1.1 CORTAR PUENTES (Apertura Morfológica)
    % Separa físicamente los objetos que están casi tocándose 
    se_separar = strel('disk', 3);
    BW_separada = imopen(BW_color, se_separar);
    
    % 1.2 CONSOLIDAR CUERPOS (Cierre Morfológico Suave)
    % Tapa los pequeños brillos especulares
    se_cerrar = strel('disk', 2);
    BW_closed = imclose(BW_separada, se_cerrar);
    
    % 1.3 RELLENO Y LIMPIEZA
    imagenD = imfill(BW_closed, 'holes');
    imagenD = bwareaopen(imagenD, 150); % Máscara final limpia

    % =========================================================
    % 2. EXTRACCIÓN DE CARACTERÍSTICAS
    % =========================================================
    stats = regionprops(imagenD, 'Area', 'Perimeter', 'Centroid', 'BoundingBox', 'Extent', 'Solidity', 'Eccentricity', 'PixelIdxList');
    
    I_out = imagenO; % Copia para pintar encima
    objetos_actuales = []; % Reseteamos la memoria del frame actual
    
    for i = 1:length(stats)
        area = stats(i).Area;
        
        if area > 150
            centro = stats(i).Centroid;
            caja = stats(i).BoundingBox;
            perimetro = stats(i).Perimeter;
            extent = stats(i).Extent;
            solidez = stats(i).Solidity;
            excentricidad = stats(i).Eccentricity; % CLAVE para diferenciar esfera de cilindro
            
            % ---------------------------------------------------------
            % RECUPERACIÓN TOPOLÓGICA (Salvar al Toroide)
            % ---------------------------------------------------------
            % Aislamos la masa sólida del objeto
            obj_mask_solid = false(size(imagenD));
            obj_mask_solid(stats(i).PixelIdxList) = true;
            
            % Cruzamos con la imagen ANTES de aplicar imfill
            obj_mask_hollow = obj_mask_solid & BW_closed; 
            
            % Calculamos el Euler directo
            euler_val = bweuler(obj_mask_hollow); 

            circularidad = 0;
            if perimetro > 0, circularidad = (4 * pi * area) / (perimetro^2); end
            
            % =========================================================
            % 3. LÓGICA DE CLASIFICACIÓN ESTRICTA Y TRACKING
            % =========================================================
            if f == 1
                % FOTOGRAMA 1: Clasificación geométrica blindada
                if euler_val < 1
                    forma = '3D Toroide'; color_texto = 'magenta';
                elseif circularidad > 0.88 && excentricidad < 0.45
                    forma = '3D Esfera'; color_texto = 'red';
                elseif solidez > 0.80
                    forma = '2D Cilindro/Cubo'; color_texto = 'green';
                else
                    forma = '3D Mono'; color_texto = 'yellow';
                end
            else
                % FOTOGRAMA > 1: Tracking por distancia mínima
                distancia_minima = inf;
                indice_mejor = -1;
                
                for j = 1:length(objetos_memoria)
                    d = norm(centro - objetos_memoria(j).centro);
                    if d < distancia_minima
                        distancia_minima = d;
                        indice_mejor = j;
                    end
                end
                
                % Límite de seguridad espacial
                if distancia_minima < 150 && indice_mejor ~= -1
                    forma = objetos_memoria(indice_mejor).etiqueta;
                    color_texto = objetos_memoria(indice_mejor).color;
                else
                    forma = 'Desconocido'; color_texto = 'white';
                end
            end
            
            % ---------------------------------------------------------
            % 4. GUARDADO DE MEMORIA Y PINTADO
            % ---------------------------------------------------------
            nuevo_obj.centro = centro;
            nuevo_obj.etiqueta = forma;
            nuevo_obj.color = color_texto;
            objetos_actuales = [objetos_actuales; nuevo_obj];
            
            % Dibujamos anotaciones
            I_out = insertShape(I_out, 'Rectangle', caja, 'Color', color_texto, 'LineWidth', 2);
            I_out = insertText(I_out, [centro(1)-20, centro(2)-20], forma, 'BoxOpacity', 0.8, 'TextColor', 'white', 'BoxColor', color_texto);
            I_out = insertMarker(I_out, centro, '+', 'Color', 'white', 'Size', 10);
        end
    end
    
    % Actualizamos la memoria global para el próximo fotograma
    objetos_memoria = objetos_actuales;
    
    % Escribir frame en el video global
    writeVideo(v, I_out);
    
    % Guardar PNG individual en la carpeta de salida
    nombre_salida = strrep(nombre_archivo, '.png', '_salida.png');
    imwrite(I_out, fullfile(carpeta_salida, nombre_salida));
    
    fprintf('Fotograma %d/%d procesado.\n', f, length(archivos));
end

close(v);
disp('¡Proceso de Tracking Completado! Revisa la carpeta de salida y el MP4.');