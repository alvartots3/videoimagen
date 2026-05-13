function [imagenD] = preprocesar_imagen(imagenO)
    % 1. Conversión a escala de grises
    I_gris = rgb2gray(imagenO);
    
    % 2. Binarización con ajuste de sensibilidad (tu método)
    umbral = graythresh(I_gris);
    umbral = umbral * 1.1
    I_bin = imbinarize(I_gris, 'adaptive', 'Sensitivity',umbral);
    I_bin = ~I_bin;
    
    % 4. Rellenar los objetos huecos
    % Ahora que la figura está unida y cerrada, imfill sí funcionará por dentro
    I_rellena = imfill(I_bin, 'holes');
    
    % 5. Limpieza de ruido
    I_mediana = medfilt2(I_rellena, [5 5]);
    
    % Aumentamos un poco el descarte de área para ignorar pequeños destellos sueltos
    I_limpia = bwareaopen(I_mediana, 200);
    
    % 6. Suavizado final del contorno
    ee = strel('square', 3);
    imagenD = imclose(I_limpia, ee);
end