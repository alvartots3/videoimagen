function imagenD = preprocesar_imagen(imagenO, imagenFondo)
% PREPROCESAR_IMAGEN - Binarización general con compensación de iluminación
% 
% Maneja tanto Escena 1 (iluminación estática, objetos móviles) como
% Escena 2 (luz móvil con sombras extremas, objetos estáticos).
%
% Técnica: Estimación de la iluminación de baja frecuencia y compensación
% aditiva. Funciona asumiendo que los cambios de iluminación son suaves
% en el espacio.

    I_gris = rgb2gray(imagenO);

    if nargin > 1 && ~isempty(imagenFondo)
        I_fondo_gris = rgb2gray(imagenFondo);
        
        % Estimación de iluminación (Low-pass filter espacial muy grande)
        % Difumina los objetos y extrae el gradiente de luz/sombra.
        filtro_gauss = fspecial('gaussian', [200 200], 60);
        
        I_suavizada = imfilter(double(I_gris), filtro_gauss, 'replicate');
        I_fondo_suavizada = imfilter(double(I_fondo_gris), filtro_gauss, 'replicate');
        
        % Calculamos cuánto se ha oscurecido la imagen actual respecto al fondo
        % debido al paso de la sombra.
        diff_sombra = I_fondo_suavizada - I_suavizada;
        
        % Solo compensamos donde hay oscurecimiento (sombra)
        diff_sombra = max(diff_sombra, 0);
        
        % Compensación aditiva: sumamos la pérdida de luz a la imagen original
        % Esto "apaga" el efecto de la sombra, devolviendo la imagen a una
        % iluminación globalmente uniforme.
        I_compensada = uint8(min(double(I_gris) + diff_sombra, 255));
        I_compensada = medfilt2(I_compensada, [5 5]);
    else
        % Si no hay imagen de referencia, asumimos iluminación original
        I_compensada = medfilt2(I_gris, [5 5]);
    end

    % Una vez compensada la iluminación, una umbralización global de Otsu
    % es suficiente para separar los objetos oscuros del fondo claro.
    umbral = graythresh(I_compensada);
    
    % Binarizamos e invertimos (queremos objetos blancos sobre fondo negro)
    I_bin = ~imbinarize(I_compensada, umbral);
    
    % Post-procesamiento morfológico estándar
    % 1. En lugar de rellenar todos los huecos (lo que destruiría los toroides),
    % solo rellenamos huecos pequeños de ruido (menores a 100 píxeles).
    I_bin_inv = ~I_bin;
    I_bin_inv = bwareaopen(I_bin_inv, 100);
    I_rellena = ~I_bin_inv;
    
    % 2. Cierre para suavizar bordes y unir piezas fragmentadas
    ee_cierre = strel('disk', 5);
    I_cerrada = imclose(I_rellena, ee_cierre);
    
    % 3. Apertura/Eliminación de ruido (artefactos pequeños o bordes de sombra residuales)
    imagenD = bwareaopen(I_cerrada, 400);
end