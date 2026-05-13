# Esquema para el Informe Técnico: Práctica de Visión Artificial

Este es un esquema con los puntos clave que debes rellenar para completar tu informe de la práctica. Puedes usarlo como plantilla base.

## 1. Introducción
- **Objetivo General:** Desarrollar un sistema de visión artificial robusto para la clasificación y tracking de objetos 3D bajo condiciones adversas de iluminación y apariencia.
- **Herramientas utilizadas:** Generación de datasets sintéticos con Blender (API Python) y procesamiento de imágenes con MATLAB (Image Processing Toolbox).

## 2. Fase de Generación de Datos (Blender)
- **Generación de Escenas:** Explicar cómo se automatizó la generación de frames mediante `ScriptBase.py`.
- **Aleatoriedad:** Detalles sobre la variación en posición, rotación, escala y tipo de objeto (simples vs 3D complejos).
- **Tipos de Escenas:**
  - *Escena 1 (Objetos Blancos):* Baseline.
  - *Escena 2 (Luz Móvil):* Cómo afecta el movimiento de la fuente de luz.
  - *Escena 3 (Contraluz/Cenital):* Retos de la oclusión de luz directa.
  - *Escena 4 y 5 (Color y Textura):* Incorporación de materiales procedurales (Noise) y cómo afectan la binarización.

## 3. Fase de Procesamiento y Análisis (MATLAB)
### 3.1. Preprocesamiento (`preprocesar_imagen.m`)
- Conversión a escala de grises.
- Binarización adaptativa ajustada (`graythresh` modificado con sensibilidad).
- Operaciones morfológicas: Relleno de huecos (`imfill`), filtro de mediana y cierre (`imclose`) para suavizar contornos y eliminar ruido o falsos destellos por reflejos.

### 3.2. Extracción de Características y Clasificación (`escenaXmat.m`)
- Extracción de propiedades (`regionprops`): Área, Perímetro, Centroide, EulerNumber, Extent, Solidez, y cálculo de Circularidad.
- **Árbol de Decisión:** Lógica utilizada en el fotograma 1 (condiciones ideales) para clasificar formas basándose en heurísticas (ej. EulerNumber < 1 para Toroide, etc.).

### 3.3. Validación de Robustez (El problema de la iluminación y texturas)
- **Impacto de las sombras y texturas:** Explicar cómo en fotogramas > 1 o escenas complejas, la sombra, el contraluz o la textura fragmentan la segmentación y falsean los descriptores de forma (cae la solidez/circularidad).
- **La Solución Robusta:** Implementación de **Tracking Espacial** basado en la distancia Euclídea del centroide. En lugar de re-clasificar bajo mala luz, el algoritmo "hereda" la etiqueta y color del objeto más cercano en el fotograma anterior, asumiendo continuidad en el movimiento/video.

## 4. Resultados y Conclusiones
- **Influencia de la iluminación:** ¿Qué tipo de luz (móvil, contraluz) generó más falsos positivos o segmentaciones rotas?
- **Efectividad del tracking:** ¿Logró mantener la identidad correcta a lo largo del vídeo?
- **Limitaciones del sistema:** ¿Qué pasa si dos objetos se cruzan (oclusión)? (Mencionar que el tracking por centroide puro podría fallar y requerir Filtro de Kalman o cruce de bounding boxes).
- **Conclusión Final:** Resumen de lo aprendido sobre la dependencia entre la calidad del preprocesamiento y el éxito de la clasificación en Visión Artificial.
