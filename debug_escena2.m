% =====================================================================
% DEBUG_ESCENA2.m  –  Diagnóstico detallado de Escena 2 (luz móvil)
%
% Objetivo: Ver qué detecta el preprocesador en cada frame y comprobar
% que la clasificación de formas funciona correctamente.
%
% Salida:  proyectoVideo/escena2_1_debug/  (3 imágenes por frame)
%          Consola: métricas por región (area, circularidad, solidez, euler)
% =====================================================================
clear; clc; close all;

addpath('C:\Users\crist\VideoImagen');

ruta_entrada = 'C:\Users\crist\VideoImagen\proyectoVideo\escena2_1';
ruta_debug   = 'C:\Users\crist\VideoImagen\proyectoVideo\escena2_1_debug';

if ~exist(ruta_debug, 'dir'), mkdir(ruta_debug); end

archivos = dir(fullfile(ruta_entrada, '*.png'));
if isempty(archivos)
    error('No hay frames en: %s', ruta_entrada);
end

fprintf('\n=== DIAGNÓSTICO ESCENA 2 ===\n');
fprintf('Frames encontrados: %d\n\n', length(archivos));

% Cargamos el fondo (frame 1) igual que en escena2mat.m
imagenFondo = imread(fullfile(ruta_entrada, archivos(1).name));

% ----------------------------------------------------------------
% Analizamos cada frame individualmente
% ----------------------------------------------------------------
for f = 1:length(archivos)
    nombre = archivos(f).name;
    imagenO = imread(fullfile(ruta_entrada, nombre));

    % Preprocesamiento igual que en escena2mat.m
    if f == 1
        imagenD = preprocesar_imagen(imagenO);
    else
        imagenD = preprocesar_imagen(imagenO, imagenFondo);
    end

    % Regiones detectadas (todas, sin filtro de área mínima aún)
    stats_all = regionprops(imagenD, 'Area', 'Perimeter', 'Centroid', ...
                    'BoundingBox', 'EulerNumber', 'Extent', 'Solidity');

    fprintf('--- Frame %02d (%s) ---\n', f, nombre);
    fprintf('  Regiones totales detectadas: %d\n', length(stats_all));

    validas = 0;
    for i = 1:length(stats_all)
        area       = stats_all(i).Area;
        perim      = max(stats_all(i).Perimeter, 1);
        euler      = stats_all(i).EulerNumber;
        solidez    = stats_all(i).Solidity;
        extent     = stats_all(i).Extent;
        circul     = (4*pi*area) / (perim^2);
        centro     = stats_all(i).Centroid;

        % Clasificamos todas las que superan el umbral mínimo
        if area >= 300
            validas = validas + 1;
            [forma, ~] = clasificar_forma(euler, solidez, circul, extent);
            fprintf('  [R%02d] Area=%6.0f | Euler=%+d | Sol=%.3f | Circ=%.3f | Ext=%.3f | Centro=(%.0f,%.0f) => %s\n', ...
                    i, area, euler, solidez, circul, extent, centro(1), centro(2), forma);
        end
    end
    if validas == 0
        fprintf('  >> NINGUNA región supera el umbral de area=300\n');
    end
    fprintf('\n');

    % ----------------------------------------------------------------
    % Figura de diagnóstico: Original | Máscara binaria | Anotado
    % ----------------------------------------------------------------
    fig = figure('Visible', 'off', 'Position', [0 0 1800 600]);

    % Panel 1: Original
    subplot(1,3,1);
    imshow(imagenO);
    I_gris  = rgb2gray(imagenO);
    pct_som = sum(I_gris(:) < 170) / numel(I_gris) * 100;
    title(sprintf('ORIGINAL  Frame %d  |  Sombra: %.0f%%', f, pct_som), ...
          'FontSize', 11, 'FontWeight', 'bold');

    % Panel 2: Máscara binaria coloreada (azul=detectado, rojo=descartado)
    subplot(1,3,2);
    mask_rgb = cat(3, zeros(size(imagenD)), zeros(size(imagenD)), double(imagenD));
    imshow(mask_rgb); hold on;
    % Marcar centroides de regiones descartadas (area<300) en rojo
    for i = 1:length(stats_all)
        if stats_all(i).Area < 300
            plot(stats_all(i).Centroid(1), stats_all(i).Centroid(2), ...
                 'r.', 'MarkerSize', 8);
        end
    end
    title(sprintf('MÁSCARA BINARIA  (azul=válido, rojo=ruido)'), ...
          'FontSize', 11, 'FontWeight', 'bold');
    hold off;

    % Panel 3: Resultado anotado
    subplot(1,3,3);
    imshow(imagenO); hold on;
    for i = 1:length(stats_all)
        area    = stats_all(i).Area;
        if area < 300, continue; end
        perim   = max(stats_all(i).Perimeter, 1);
        euler   = stats_all(i).EulerNumber;
        solidez = stats_all(i).Solidity;
        extent  = stats_all(i).Extent;
        circul  = (4*pi*area) / (perim^2);
        centro  = stats_all(i).Centroid;
        caja    = stats_all(i).BoundingBox;

        [forma, ctxt] = clasificar_forma(euler, solidez, circul, extent);

        plot(centro(1), centro(2), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
        rectangle('Position', caja, 'EdgeColor', 'g', 'LineWidth', 2);
        text(centro(1)+4, centro(2)-12, forma, ...
             'Color', ctxt, 'FontSize', 8, 'FontWeight', 'bold', ...
             'BackgroundColor', 'k');
        text(centro(1)+4, centro(2)+10, ...
             sprintf('E=%d S=%.2f C=%.2f', euler, solidez, circul), ...
             'Color', 'white', 'FontSize', 7, 'BackgroundColor', [0.2 0.2 0.2]);
    end
    title(sprintf('RESULTADO  Frame %d  |  %d objeto(s) detectado(s)', f, validas), ...
          'FontSize', 11, 'FontWeight', 'bold');
    hold off;

    % Guardar
    nombre_sal = sprintf('debug_frame_%02d.png', f);
    saveas(fig, fullfile(ruta_debug, nombre_sal));
    close(fig);
    fprintf('  >> Guardado: %s\n\n', nombre_sal);
end

fprintf('=== FIN DIAGNÓSTICO ===\n');
fprintf('Capturas en: %s\n', ruta_debug);
