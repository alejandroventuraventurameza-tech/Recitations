%% Script 00: Importación de datos — del Excel al .mat
%{
-----------------------------------------------------------------------
Autor    : Alejandro Ventura
Curso    : Macroeconomía II
Fecha    : 2026
-----------------------------------------------------------------------
PROPÓSITO
    Este script es el PRIMER PASO del flujo de trabajo. Lee el archivo
    Excel con los datos crudos, los organiza en variables de MATLAB y
    los guarda en formato .mat para ser usado por los scripts de análisis.

    ¿Por qué usar .mat en lugar de leer el Excel directamente?
    Porque los archivos .mat son mucho más rápidos de cargar y mantienen
    los tipos de datos exactamente como los definimos aquí. En proyectos
    grandes con muchas series, esta diferencia de velocidad importa.

FUENTES DE LOS DATOS (economía de EEUU, datos trimestrales)
    - BEA (Bureau of Economic Analysis): PIB, Consumo, Inversión
      https://www.bea.gov/
    - BLS (Bureau of Labor Statistics): Horas, Empleo, Salario, TFP
      https://www.bls.gov/
    - Los datos cubren: 1947 Q1 — 2016 Q4 (280 trimestres)

ARCHIVOS QUE GENERA
    1. data_matlab_agregada.mat  → usado por Script_01_Hechos_Estilizados.m

NOTA SOBRE PBI_TFP_anual.mat
    Ese archivo proviene de datos anuales del BLS (mfp_tables_historical.xlsx)
    y requiere un proceso de importación separado, no incluido aquí.
-----------------------------------------------------------------------
%}

%% -----------------------------------------------------------------------
%  [0] Limpieza del entorno de trabajo
%  -----------------------------------------------------------------------
%  Buena práctica: siempre empezar con el workspace limpio para evitar
%  que variables de sesiones anteriores interfieran con los resultados.
%  -----------------------------------------------------------------------
clear all
clc

%% -----------------------------------------------------------------------
%  [1] Definición de rutas
%  -----------------------------------------------------------------------
%  Usamos rutas relativas para que el script funcione en cualquier
%  computadora, siempre que la carpeta de trabajo sea la correcta.
%  -----------------------------------------------------------------------
archivo_excel = fullfile('data', 'Data_Matlab.xlsx');

% Verificar que el archivo existe antes de continuar
if ~isfile(archivo_excel)
    error('No se encontró el archivo: %s\nVerificá que estés en la carpeta correcta.', archivo_excel);
end

fprintf('Archivo encontrado: %s\n', archivo_excel);

%% -----------------------------------------------------------------------
%  [2] Lectura del sheet "Matlab_agregado"
%  -----------------------------------------------------------------------
%  Este sheet contiene las variables en NIVELES AGREGADOS (no per cápita)
%  y en logaritmo natural. Ya incluye el stock de capital pre-calculado.
%
%  DECISIÓN METODOLÓGICA — ¿Por qué "nonfarm"?
%  Las series de horas y empleo usan el sector "nonfarm" (no agrícola),
%  que es el estándar en la literatura macro de EEUU. El sector agrícola
%  tiene fluctuaciones estacionales muy fuertes e irregulares que
%  distorsionan el análisis del ciclo económico.
%
%  Variables en este sheet:
%   indice               → índice numérico (1 = 1947 Q1)
%   Fecha                → año decimal (ej: 1954.25 = 1954 Q2)
%   ln_gdp               → log del PIB real agregado
%   ln_consumo_real      → log del consumo real
%   ln_inv_privada_real_bd → log de la inversión privada real
%   ln_stock_capital     → log del stock de capital (ver nota abajo)
%   ln_horas_total_nonfarm → log de horas totales trabajadas (sector nonfarm)
%   ln_empleo_total_nonfarm → log del empleo total (sector nonfarm)
%   ln_salario_real_porhora → log del salario real por hora
%   ln_productividad     → log de la productividad laboral
%  -----------------------------------------------------------------------
opts = detectImportOptions(archivo_excel, 'Sheet', 'Matlab_agregado');
opts = setvartype(opts, opts.VariableNames, 'double');
T = readtable(archivo_excel, opts, 'Sheet', 'Matlab_agregado');

fprintf('Sheet "Matlab_agregado" leído: %d filas x %d columnas\n', height(T), width(T));

%% -----------------------------------------------------------------------
%  [3] Extracción y asignación de variables
%  -----------------------------------------------------------------------
%  Extraemos cada columna como un vector columna y la nombramos igual
%  que en el script de análisis, para que la carga sea directa.
%  -----------------------------------------------------------------------
Fecha                 = T.Fecha;                    % Vector de fechas decimales
ln_gdp                = T.ln_gdp;                   % Log PIB real
ln_consumo_real       = T.ln_consumo_real;           % Log Consumo real
ln_inv_privada_real_bd = T.ln_inv_privada_real_bd;  % Log Inversión privada real
ln_stock_capital      = T.ln_stock_capital;          % Log Stock de capital
ln_horas_total_nonfarm = T.ln_horas_total_nonfarm;  % Log Horas nonfarm
ln_empleo_total_nonfarm = T.ln_empleo_total_nonfarm; % Log Empleo nonfarm
ln_salario_real_porhora = T.ln_salario_real_porhora; % Log Salario real/hora
ln_productividad      = T.ln_productividad;          % Log Productividad laboral

%% -----------------------------------------------------------------------
%  [4] Nota sobre el stock de capital y el período de análisis
%  -----------------------------------------------------------------------
%  DECISIÓN METODOLÓGICA — El método de inventario perpetuo:
%
%  El stock de capital no se observa directamente. Se calcula a partir
%  de la inversión usando la fórmula:
%
%       K(t) = (1 - delta) * K(t-1) + I(t)
%
%  donde delta = 0.03 (tasa de depreciación trimestral) y K(0) es un
%  valor inicial tomado del BLS para 1948.
%
%  PROBLEMA: los primeros años del stock calculado son poco confiables
%  porque dependen mucho del valor inicial K(0). La serie necesita
%  un período de "quemado" (burn-in) de aproximadamente 6 años para
%  que el error inicial se disipe.
%
%  Por eso el análisis comienza en 1954 Q2 (índice 30 del vector).
%  En el Excel se puede ver que los índices 1-4 (1947) tienen ceros
%  en casi todas las variables per cápita, y que el capital recién
%  se estabiliza alrededor de 1954.
%
%  PERÍODO DE ANÁLISIS: índices 30 a 277 → 1954 Q2 a 2016 Q1
%  -----------------------------------------------------------------------
idx_inicio = 30;   % 1954 Q2
idx_fin    = 277;  % 2016 Q1

fprintf('\nPeríodo de análisis:\n');
fprintf('  Inicio: %.2f (índice %d)\n', Fecha(idx_inicio), idx_inicio);
fprintf('  Fin:    %.2f (índice %d)\n', Fecha(idx_fin),    idx_fin);
fprintf('  Total:  %d trimestres\n', idx_fin - idx_inicio + 1);

%% -----------------------------------------------------------------------
%  [5] Control de calidad: verificar que no haya ceros fuera del burn-in
%  -----------------------------------------------------------------------
%  Chequeamos que dentro del período de análisis no queden ceros en
%  variables que deberían tener datos completos.
%  -----------------------------------------------------------------------
vars_check = {'ln_gdp', 'ln_consumo_real', 'ln_inv_privada_real_bd', ...
              'ln_horas_total_nonfarm', 'ln_empleo_total_nonfarm', ...
              'ln_salario_real_porhora', 'ln_productividad'};

fprintf('\nControl de calidad (período de análisis):\n');
muestra_gdp = ln_gdp(idx_inicio:idx_fin);
for v = 1:length(vars_check)
    eval(sprintf('serie = %s(idx_inicio:idx_fin);', vars_check{v}));
    n_ceros = sum(serie == 0);
    n_nan   = sum(isnan(serie));
    if n_ceros == 0 && n_nan == 0
        fprintf('  %-30s OK (sin ceros ni NaN)\n', vars_check{v});
    else
        fprintf('  %-30s ADVERTENCIA: %d ceros, %d NaN\n', vars_check{v}, n_ceros, n_nan);
    end
end

% El capital puede tener ceros al final (datos no disponibles)
n_ceros_k = sum(ln_stock_capital(idx_inicio:idx_fin) == 0);
fprintf('  %-30s %d ceros al final de la muestra (datos no disponibles)\n', ...
        'ln_stock_capital', n_ceros_k);

%% -----------------------------------------------------------------------
%  [6] Guardar como .mat
%  -----------------------------------------------------------------------
%  Guardamos todas las variables en un único archivo .mat.
%  Al hacer 'load data_matlab_agregada.mat' en el script de análisis,
%  todas estas variables aparecerán automáticamente en el workspace.
%  -----------------------------------------------------------------------
save('data_matlab_agregada.mat', ...
     'Fecha', ...
     'ln_gdp', ...
     'ln_consumo_real', ...
     'ln_inv_privada_real_bd', ...
     'ln_stock_capital', ...
     'ln_horas_total_nonfarm', ...
     'ln_empleo_total_nonfarm', ...
     'ln_salario_real_porhora', ...
     'ln_productividad');

fprintf('\nArchivo guardado: data_matlab_agregada.mat\n');
fprintf('Variables incluidas:\n');
fprintf('  Fecha, ln_gdp, ln_consumo_real, ln_inv_privada_real_bd,\n');
fprintf('  ln_stock_capital, ln_horas_total_nonfarm, ln_empleo_total_nonfarm,\n');
fprintf('  ln_salario_real_porhora, ln_productividad\n');

%% -----------------------------------------------------------------------
%  [7] Estadísticos descriptivos básicos (verificación visual)
%  -----------------------------------------------------------------------
%  Mostrar un resumen rápido para confirmar que los datos tienen sentido.
%  -----------------------------------------------------------------------
fprintf('\n--- Estadísticos básicos del período de análisis (1954 Q2 - 2016 Q1) ---\n');
fprintf('%-35s %8s %8s %8s %8s\n', 'Variable', 'Min', 'Max', 'Media', 'Obs.');

variables = {ln_gdp, ln_consumo_real, ln_inv_privada_real_bd, ...
             ln_stock_capital, ln_horas_total_nonfarm, ...
             ln_empleo_total_nonfarm, ln_salario_real_porhora, ln_productividad};
nombres_cortos = {'ln_gdp', 'ln_consumo_real', 'ln_inv_privada_real_bd', ...
                  'ln_stock_capital', 'ln_horas_nonfarm', ...
                  'ln_empleo_nonfarm', 'ln_salario_real', 'ln_productividad'};

for v = 1:length(variables)
    s = variables{v}(idx_inicio:idx_fin);
    s = s(s ~= 0);  % Excluir ceros del cálculo
    fprintf('%-35s %8.3f %8.3f %8.3f %8d\n', ...
            nombres_cortos{v}, min(s), max(s), mean(s), length(s));
end

fprintf('\nScript 00 completado exitosamente.\n');
fprintf('Siguiente paso: correr Script_01_Hechos_Estilizados.m\n');

%% -----------------------------------------------------------------------
%  [REFERENCIA] Cálculo del stock de capital por inventario perpetuo
%  -----------------------------------------------------------------------
%  Esta sección está COMPLETAMENTE COMENTADA. No se ejecuta.
%  Se incluye como referencia pedagógica para mostrar cómo se construyó
%  la serie ln_stock_capital que ya viene pre-calculada en el Excel.
%
%  En nuestro flujo actual usamos el valor ya calculado en el .mat.
%  Pero si los alumnos quisieran replicarlo desde cero, este sería el código.
%
%  FÓRMULA (método de inventario perpetuo):
%
%       K(t) = (1 - delta) * K(t-1) + I(t)
%
%  Desplegando recursivamente desde el período inicial:
%
%       K(t) = (1-delta)^t * K(0)  +  sum_{j=0}^{t-1} (1-delta)^j * I(t-j)
%
%  PARÁMETROS:
%       K(0) = 2754.555  → stock de capital en 1948 Q1
%                          (fuente: BLS, mfp_tables_historical.xlsx, hoja XG, celda D9)
%       delta = 0.03     → tasa de depreciación trimestral
%
%  DATOS NECESARIOS:
%       inversion_privada_real → columna del sheet "Data_Matlab_fijo"
%                                en niveles (miles de millones de USD)
%                                disponible desde 1947 Q1
%  -----------------------------------------------------------------------
%
% % --- Parámetros ---
% ko    = 2754.555;   % Stock de capital inicial (1948 Q1), en miles de mill. USD
% delta = 0.03;       % Tasa de depreciación trimestral
%
% % --- Leer la inversión desde el sheet "Data_Matlab_fijo" ---
% % (requiere haber leído ese sheet previamente con readtable)
% % La inversión empieza desde 1949 Q1 (índice 9 del vector completo)
% inv_data = inversion_privada_real(9:end)';   % vector fila, desde 1949 Q1
% T_inv    = length(inv_data);                 % número de trimestres
%
% % --- Vector de pesos de depreciación acumulada ---
% % d(j+1) = (1-delta)^j  para j = 0, 1, ..., T_inv-1
% % Representa cuánto "vale" hoy una unidad de inversión de hace j períodos
% d = zeros(1, T_inv);
% for j = 0:(T_inv - 1)
%     d(j+1) = (1 - delta)^j;
% end
% D = d';   % convertir a vector columna
%
% % --- Bucle principal: acumular capital período a período ---
% % S(t) = suma ponderada de la inversión hasta el período t
% % k(t) = capital heredado del período inicial + inversión acumulada
% k = zeros(1, T_inv);
% S = zeros(1, T_inv);
% for t = 1:T_inv
%     % inv_data(end-t+1:end) son las t últimas observaciones de inversión
%     % D(1:t) son los pesos correspondientes (más reciente = peso mayor)
%     S(t) = inv_data(end-t+1:end) * D(1:t);
%     k(t) = ((1 - delta)^t) * ko + S(t);
% end
%
% % --- Tomar logaritmo ---
% ln_k_calculado = log(k);
%
% % NOTA: Los primeros ~24 trimestres (6 años) son poco confiables
% % porque dependen mucho del valor inicial ko. Por eso el análisis
% % empieza en 1954 Q2 (índice 30 del vector completo), no antes.
% -----------------------------------------------------------------------
