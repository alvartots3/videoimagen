% escena5_texturas.m
% Arquitectura: Varianza Local (stdfilt) + HSV + Tracking

% =========================================================
% 1. CONFIGURACIÓN DE RUTAS EXACTA
% =========================================================
ruta_base = 'C:\Users\crist\VideoImagen\proyectoVideo';
nombre_escena = 'escena5_20260515_110156'; % Tu carpeta exacta
carpeta_entrada = fullfile(ruta_base, nombre_escena);
carpeta_salida = fullfile(ruta_base, [nombre_escena, '_salida']);

% Crea la carpeta de salida automáticamente si no existe
if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

archivos = dir(fullfile(carpeta_entrada, '*.png'));

if isempty(archivos)
    error('No se han encontrado fotos en: %s', carpeta_entrada);
end

% Configurar video de salida
ruta_video = fullfile(ruta_base, 'escena5_texturas_video.mp4');
v = VideoWriter(ruta_video, 'MPEG-4');
v.FrameRate = 12;
open(v);

fprintf('Procesando %d fotogramas de texturas procedimentales...\n', length(archivos));

% TRACKING: Memoria del fotograma anterior
objetos_memoria = []; 

for f = 1:length(archivos)
    nombre_archivo = archivos(f).name;
    ruta_completa = fullfile(carpeta_entrada, nombre_archivo);
    
    imagenO = imread(ruta_completa);
    
    % =========================================================
    % 2. PREPROCESADO: FUSIÓN DE VARIANZA Y SATURACIÓN
    % =========================================================
    % 2.1 Análisis Cromático (HSV)
    I_hsv = rgb2hsv(imagenO);
    Saturation = I_hsv(:,:,2); 
    BW_color = Saturation > 0.20; % Captura parches de color vivo
    
    % 2.2 Análisis de Textura / Varianza (stdfilt)
    I_gray = im2double(rgb2gray(imagenO));
    % stdfilt calcula la desviación estándar local para pillar el ajedrez/voronoi
    I_tex = stdfilt(I_gray, ones(5)); 
    BW_tex = I_tex > 0.025; 
    
    % 2.3 Fusión de Descriptores
    BW_combined = BW_color | BW_tex;
    
    % 2.4 Refinamiento Morfológico
    se_separar = strel('disk', 2);
    BW_separada = imopen(BW_combined, se_separar); % Evita que se peguen objetos cercanos
    
    se_cerrar = strel('disk', 4);
    BW_closed = imclose(BW_separada, se_cerrar); % Consolida la malla de la textura
    
    % Rellenamos todo el interior para obtener la silueta pura
    imagenD = imfill(BW_closed, 'holes');
    imagenD = bwareaopen(imagenD, 150); % Eliminamos ruido minúsculo del suelo

    % =========================================================
    % 3. EXTRACCIÓN DE CARACTERÍSTICAS DE SILUETA
    % =========================================================
    stats = regionprops(imagenD, 'Area', 'Perimeter', 'Centroid', 'BoundingBox', 'Extent', 'Solidity', 'Eccentricity');
    
    I_out = imagenO; % Copia para pintar
    objetos_actuales = []; 
    
    for i = 1:length(stats)
        area = stats(i).Area;
        
        if area > 150
            centro = stats(i).Centroid;
            caja = stats(i).BoundingBox;
            perimetro = stats(i).Perimeter;
            extent = stats(i).Extent;
            solidez = stats(i).Solidity;
            excentricidad = stats(i).Eccentricity;

            circularidad = 0;
            if perimetro > 0, circularidad = (4 * pi * area) / (perimetro^2); end
            
            % =========================================================
            % 4. CLASIFICACIÓN (Solo Silueta) Y TRACKING
            % =========================================================
            if f == 1
                % FOTOGRAMA 1: Clasificación basada estrictamente en la envolvente exterior
                if circularidad > 0.85 && extent < 0.85 && excentricidad < 0.45
                    forma = '3D Esfera'; color_texto = 'red';
                elseif solidez > 0.85
                    forma = '2D Simple'; color_texto = 'green';
                else
                    forma = '3D Complejo'; color_texto = 'magenta';
                end
            else
                % FOTOGRAMA > 1: Tracking Espacial Euclídeo
                distancia_minima = inf;
                indice_mejor = -1;
                
                for j = 1:length(objetos_memoria)
                    d = norm(centro - objetos_memoria(j).centro);
                    if d < distancia_minima
                        distancia_minima = d;
                        indice_mejor = j;
                    end
                end
                
                % Límite de seguridad
                if distancia_minima < 150 && indice_mejor ~= -1
                    forma = objetos_memoria(indice_mejor).etiqueta;
                    color_texto = objetos_memoria(indice_mejor).color;
                else
                    forma = 'Desconocido'; color_texto = 'white';
                end
            end
            
            % ---------------------------------------------------------
            % 5. GUARDADO DE MEMORIA Y PINTADO
            % ---------------------------------------------------------
            nuevo_obj.centro = centro;
            nuevo_obj.etiqueta = forma;
            nuevo_obj.color = color_texto;
            objetos_actuales = [objetos_actuales; nuevo_obj];
            
            I_out = insertShape(I_out, 'Rectangle', caja, 'Color', color_texto, 'LineWidth', 2);
            I_out = insertText(I_out, [centro(1)-20, centro(2)-20], forma, 'BoxOpacity', 0.8, 'TextColor', 'white', 'BoxColor', color_texto);
            I_out = insertMarker(I_out, centro, '+', 'Color', 'white', 'Size', 10);
        end
    end
    
    objetos_memoria = objetos_actuales;
    
    writeVideo(v, I_out);
    nombre_salida = strrep(nombre_archivo, '.png', '_salida.png');
    imwrite(I_out, fullfile(carpeta_salida, nombre_salida));
    
    fprintf('Fotograma %d/%d procesado.\n', f, length(archivos));
end

close(v);
disp(['¡Victoria! Escena 5 procesada.']);
disp(['Revisa tu video en: ', ruta_video]);