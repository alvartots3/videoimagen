% =====================================================================
% ESCENA2MAT.m  –  Procesamiento robusto de la Escena 2 (luz móvil)
%
% Técnica principal: Sustracción de fondo + Tracking espacial
%
% El reto de la escena 2 es que la LUZ SE MUEVE: la sombra pasa sobre
% los objetos, haciendo que su nivel de gris converja con el fondo.
% La sustracción de fondo compara cada frame con el frame 1 (sin sombra)
% y detecta los píxeles que han cambiado, que son exactamente los objetos.
%
% Entrada : C:\Users\crist\VideoImagen\proyectoVideo\escena2_1  (usa sólo esta secuencia real)
% Salida  : C:\Users\crist\VideoImagen\proyectoVideo\escena2_1_salida + video MP4
% =====================================================================
clear; clc; close all;

ruta_base     = 'C:\Users\crist\VideoImagen\proyectoVideo';
nombre_escena = 'escena2_1';
carpeta_entrada =  fullfile(ruta_base, nombre_escena);
carpeta_salida  = fullfile(ruta_base, [nombre_escena, '_salida']);

fprintf('\n=== Procesando %s (Escena 2 – Luz Móvil) ===\n', nombre_escena);

if ~exist(carpeta_salida, 'dir'), mkdir(carpeta_salida); end

archivos = dir(fullfile(carpeta_entrada, '*.png'));
if isempty(archivos)
    error('Sin imágenes en: %s', carpeta_entrada);
end
fprintf('Encontrados %d fotogramas.\n', length(archivos));

% -------------------------------------------------------
% Frame de referencia: cargamos el PRIMER frame (sin sombra)
% Este es el "modelo de fondo limpio"
% -------------------------------------------------------
imagenFondo = imread(fullfile(carpeta_entrada, archivos(1).name));
fprintf('Fondo de referencia: %s\n', archivos(1).name);

objetos_memoria = [];

for f = 1:length(archivos)
    nombre_archivo = archivos(f).name;
    imagenO        = imread(fullfile(carpeta_entrada, nombre_archivo));

    % -------------------------------------------------------
    % PREPROCESAMIENTO CON SUSTRACCIÓN DE FONDO
    % -------------------------------------------------------
    if f == 1
        % Frame 1: Método clásico (es el fondo de referencia)
        imagenD = preprocesar_imagen(imagenO);
    else
        % Frames 2+: Sustracción de fondo para ignorar la sombra
        imagenD = preprocesar_imagen(imagenO, imagenFondo);
    end

    if f == 1
        % Pre-computamos las detecciones estáticas usando el frame 5
        frame_ref_idx = min(5, length(archivos));
        imagen_ref = imread(fullfile(carpeta_entrada, archivos(frame_ref_idx).name));
        imagenD_ref = preprocesar_imagen(imagen_ref, imagenFondo);
        stats_memoria = regionprops(imagenD_ref, 'Area', 'Perimeter', 'Centroid', ...
                            'BoundingBox', 'EulerNumber', 'Extent', 'Solidity');
        
        % Inicializar memoria de características históricas para cada objeto estático
        for i = 1:length(stats_memoria)
            stats_memoria(i).best_euler   = stats_memoria(i).EulerNumber;
            stats_memoria(i).best_solidez = stats_memoria(i).Solidity;
            stats_memoria(i).best_circ    = (4 * pi * stats_memoria(i).Area) / (max(stats_memoria(i).Perimeter, 1)^2);
            stats_memoria(i).best_extent  = stats_memoria(i).Extent;
            [forma, color_txt] = clasificar_forma(stats_memoria(i).best_euler, ...
                                                  stats_memoria(i).best_solidez, ...
                                                  stats_memoria(i).best_circ, ...
                                                  stats_memoria(i).best_extent);
            stats_memoria(i).etiqueta = forma;
            stats_memoria(i).color    = color_txt;
        end
    end

    % Las cajas (BoundingBox) y centros son 100% estáticos de frame 5
    stats = stats_memoria;

    % Pero extraemos las stats del frame actual para mejorar nuestra clasificación histórica
    stats_actuales = regionprops(imagenD, 'Area', 'Perimeter', 'Centroid', ...
                                 'BoundingBox', 'EulerNumber', 'Extent', 'Solidity');

    fig = figure('Visible', 'off');
    imshow(imagenO); hold on;

    % Título informativo con estado de la sombra
    I_gris   = rgb2gray(imagenO);
    pct_somb = sum(I_gris(:) < 170) / numel(I_gris) * 100;
    title(sprintf('Escena 2 – Frame %d/%d  |  Sombra: %.0f%% imagen', ...
                  f, length(archivos), pct_somb), ...
          'FontSize', 11, 'FontWeight', 'bold');

    objetos_actuales = [];

    for i = 1:length(stats)
        area_congelada = stats(i).Area;
        if area_congelada < 300, continue; end

        centro_congelado = stats(i).Centroid;
        caja_congelada   = stats(i).BoundingBox;

        % --- Búsqueda de características dinámicas en el frame actual ---
        % Buscamos si en este frame detectamos algo cerca del centroide estático
        if ~isempty(stats_actuales)
            dists = arrayfun(@(s) norm(centro_congelado - s.Centroid), stats_actuales);
            [dmin, idx_actual] = min(dists);
            
            if dmin < 100
                % Si encontramos el objeto en el frame actual, comprobamos si revela una mejor forma
                obj_actual = stats_actuales(idx_actual);
                circ_actual = (4 * pi * obj_actual.Area) / (max(obj_actual.Perimeter, 1)^2);
                
                % Un toroide eventualmente revelará su hueco (Euler < 1)
                if obj_actual.EulerNumber < stats_memoria(i).best_euler
                    stats_memoria(i).best_euler = obj_actual.EulerNumber;
                end
                
                % Formas sin hueco se ven mejor cuando no están fragmentadas por la sombra
                if obj_actual.Solidity > stats_memoria(i).best_solidez
                    stats_memoria(i).best_solidez = obj_actual.Solidity;
                    stats_memoria(i).best_circ    = circ_actual;
                    stats_memoria(i).best_extent  = obj_actual.Extent;
                end
                
                % Reclasificar con las mejores características históricas
                [forma, color_txt] = clasificar_forma(stats_memoria(i).best_euler, ...
                                                      stats_memoria(i).best_solidez, ...
                                                      stats_memoria(i).best_circ, ...
                                                      stats_memoria(i).best_extent);
                stats_memoria(i).etiqueta = forma;
                stats_memoria(i).color    = color_txt;
            end
        end

        % Usamos la etiqueta históricamente acumulada, pero la caja estática
        forma     = stats_memoria(i).etiqueta;
        color_txt = stats_memoria(i).color;

        nuevo.centro   = centro_congelado;
        nuevo.etiqueta = forma;
        nuevo.color    = color_txt;
        objetos_actuales = [objetos_actuales; nuevo]; %#ok<AGROW>

        % Dibujar anotaciones usando las coordenadas estáticas!
        plot(centro_congelado(1), centro_congelado(2), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
        rectangle('Position', caja_congelada, 'EdgeColor', 'g', 'LineWidth', 2);
        text(centro_congelado(1)+4, centro_congelado(2)-12, forma, ...
             'Color', color_txt, 'FontSize', 9, 'FontWeight', 'bold', ...
             'BackgroundColor', 'k');
        
        % Mostrar las mejores características logradas hasta ahora
        text(centro_congelado(1)+4, centro_congelado(2)+14, ...
             sprintf('A:%.0f C:%.2f E:%d', area_congelada, stats_memoria(i).best_circ, stats_memoria(i).best_euler), ...
             'Color', 'white', 'FontSize', 7);
    end

    objetos_memoria = objetos_actuales;
    hold off;

    nombre_salida = strrep(nombre_archivo, '.png', '_salida.png');
    saveas(fig, fullfile(carpeta_salida, nombre_salida));
    close(fig);

    fprintf('  Frame %02d (sombra=%.0f%%): %d objetos detectados.\n', ...
            f, pct_somb, length(objetos_actuales));
end

% --- Generar vídeo ---
ruta_video   = fullfile(ruta_base, [nombre_escena, '_resultado.mp4']);
archivos_sal = dir(fullfile(carpeta_salida, '*_salida.png'));
try
    v = VideoWriter(ruta_video, 'MPEG-4');
    v.FrameRate = 1;
    open(v);
    for k = 1:length(archivos_sal)
        img = imread(fullfile(carpeta_salida, archivos_sal(k).name));
        writeVideo(v, img);
    end
    close(v);
    fprintf('\nVideo generado: %s\n', ruta_video);
catch ME
    warning('Error generando video: %s', ME.message);
end

disp('=== ESCENA 2 COMPLETA ===');



