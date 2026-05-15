function imagenD = preprocesar_imagen(imagenO, imagenFondo)
% PREPROCESAR_IMAGEN - Binarización bidireccional con compensación de iluminación
%
% Detecta objetos MÁS OSCUROS y MÁS CLAROS que el fondo (clave para Escena 2,
% donde los toroides son blancos y los cubos son grises oscuros sobre
% un fondo gris medio).
%
% Sin fondo  : umbral bidireccional directo sobre frame 1
% Con fondo  : compensación de sombra + umbral bidireccional

    I_gris = rgb2gray(imagenO);
    I_med  = medfilt2(I_gris, [5 5]);

    if nargin > 1 && ~isempty(imagenFondo)
        % ---- Modo con fondo de referencia (frames 2-N, luz móvil) ----
        I_fondo_gris = rgb2gray(imagenFondo);
        I_fondo_med  = medfilt2(I_fondo_gris, [5 5]);

        % Estimación del gradiente de sombra (filtro Gaussiano de baja frecuencia)
        filtro = fspecial('gaussian', [101 101], 30);
        I_suav       = imfilter(double(I_med),       filtro, 'replicate');
        I_fondo_suav = imfilter(double(I_fondo_med), filtro, 'replicate');

        % Compensación aditiva de la sombra
        diff_somb = max(I_fondo_suav - I_suav, 0);
        I_comp    = uint8(min(double(I_med) + diff_somb, 255));

        % Nivel de fondo de referencia (mediana del frame 1)
        bg = double(median(I_fondo_med(:)));

        % Umbral bidireccional: objetos oscuros Y objetos claros
        dark_mask  = I_comp < uint8(bg * 0.82);
        light_mask = I_comp > uint8(min(bg * 1.07, 255));
        I_bin = dark_mask | light_mask;

    else
        % ---- Modo sin fondo (frame 1 de escena2, escena1, etc.) ----
        bg = double(median(I_med(:)));

        dark_mask  = I_med < uint8(bg * 0.82);
        light_mask = I_med > uint8(min(bg * 1.07, 255));
        I_bin = dark_mask | light_mask;
    end

    % ---- Morfología: preservar huecos de toroides ----
    % Solo eliminar huecos MUY pequeños (ruido), conservar los grandes (toroides)
    inv       = ~I_bin;
    inv_clean = bwareaopen(inv, 150);   % elimina huecos de ruido < 150 px
    I_rellena = ~inv_clean;

    % Cierre suave para unir bordes fragmentados
    I_cerrada = imclose(I_rellena, strel('disk', 4));

    % Eliminar regiones muy pequeñas (ruido global)
    imagenD = bwareaopen(I_cerrada, 350);
end