%% Script 01: Hechos estilizados del ciclo económico — EE.UU.
%{
-----------------------------------------------------------------------
Autor    : Alejandro Ventura
Curso    : Macroeconomía II
Fecha    : 2026
-----------------------------------------------------------------------
PROPÓSITO
    Este script replica los hechos estilizados del ciclo económico de
    EE.UU. usando datos trimestrales. El flujo es:

        1. Cargar los datos (generados por Script_00)
        2. Graficar las series en niveles (logaritmos)
        3. Separar tendencia y ciclo con el filtro Hodrick-Prescott
        4. Graficar los componentes cíclicos
        5. Calcular los estadísticos canónicos del ciclo

HECHOS ESTILIZADOS QUE BUSCAMOS REPLICAR
    Para cada variable X, se calculan tres estadísticos respecto al
    componente cíclico del PIB:

    (a) Volatilidad relativa  = std(ciclo_X) / std(ciclo_PIB)
        → ¿cuánto se mueve X en relación al PIB?
        Hecho conocido: la inversión es ~3x más volátil que el PIB;
        el consumo es ~0.8x (más suave).

    (b) Correlación contemporánea con el PIB = corr(ciclo_X, ciclo_PIB)
        → ¿es procíclica (>0), contracíclica (<0) o acíclica (~0)?

    (c) Autocorrelación de orden 1 = corr(ciclo_X(t), ciclo_X(t-1))
        → ¿qué tan persistente es el componente cíclico?

REQUISITO PREVIO
    Haber corrido Script_00_Importar_Datos.m para generar:
        - data_matlab_agregada.mat
        - PBI_TFP_anual.mat (ver nota al final del script)

NOTA SOBRE COMPATIBILIDAD
    Testeado en MATLAB R2022b o posterior.
    Requiere el Econometrics Toolbox (para hpfilter y autocorr).
    CAMBIO DE SINTAXIS (R2022b+):
      hpfilter ahora usa par nombre-valor: hpfilter(y, 'Smoothing', lambda)
      La sintaxis antigua hpfilter(y, lambda) genera error en versiones nuevas.
-----------------------------------------------------------------------
%}

%% -----------------------------------------------------------------------
%  [0] Limpieza del entorno
%  -----------------------------------------------------------------------
clear all
clc
close all   % Cierra todas las figuras abiertas

%% -----------------------------------------------------------------------
%  [1] Carga de datos
%  -----------------------------------------------------------------------
%  Cargamos el .mat generado por Script_00. Al ejecutar esta línea,
%  todas las variables guardadas aparecen directamente en el workspace.
%  -----------------------------------------------------------------------
load data_matlab_agregada.mat;

%  Renombramos a nombres cortos para mayor comodidad al escribir código.
%  El 'clear' posterior limpia los nombres largos originales para no
%  tener el mismo dato dos veces en memoria con nombres distintos.
ln_y    = ln_gdp;                    % Log PIB real
ln_c    = ln_consumo_real;           % Log Consumo real
ln_inv  = ln_inv_privada_real_bd;    % Log Inversión privada real
ln_k    = ln_stock_capital;          % Log Stock de capital
ln_h    = ln_horas_total_nonfarm;    % Log Horas trabajadas (nonfarm)
ln_e    = ln_empleo_total_nonfarm;   % Log Empleo (nonfarm)
ln_w    = ln_salario_real_porhora;   % Log Salario real por hora
ln_prod = ln_productividad;          % Log Productividad laboral

clear ln_gdp ln_consumo_real ln_inv_privada_real_bd ln_stock_capital ...
      ln_horas_total_nonfarm ln_empleo_total_nonfarm ...
      ln_salario_real_porhora ln_productividad;

%  Definimos el período de análisis (ver explicación en Script_00)
%  Índice 30 = 1954 Q2 | Índice 277 = 2016 Q1
t0 = 30;
t1 = 277;
T_muestra = Fecha(t0:t1);   % Vector de fechas del período analizado

fprintf('Datos cargados. Período de análisis: %.2f — %.2f (%d trimestres)\n', ...
        T_muestra(1), T_muestra(end), length(T_muestra));

%% -----------------------------------------------------------------------
%  [2] Series en niveles: gráficas
%  -----------------------------------------------------------------------
%  Antes de calcular cualquier estadístico, siempre conviene graficar
%  las series en niveles para detectar valores atípicos o errores.
%
%  INTERPRETACIÓN:
%  Todas las series están en logaritmo, así que la pendiente de cada
%  línea representa aproximadamente la tasa de crecimiento promedio.
%  -----------------------------------------------------------------------

% --- Figura 1: PIB, Consumo e Inversión ---
figure('Name', 'Series en niveles: Y, C, I')
plot(T_muestra, ln_y(t0:t1), '--b', ...
     T_muestra, ln_c(t0:t1), '-k',  ...
     T_muestra, ln_inv(t0:t1), '-r', 'LineWidth', 2);
xlim([1954 2017]);
xlabel('Año');
ylabel('Log (nivel)');
title('Series macroeconómicas en niveles — EE.UU. (1954–2016)');
leg = legend('Ln(PIB)', 'Ln(Consumo)', 'Ln(Inversión)');
set(leg, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
legend('boxoff');
grid on;
orient landscape;
saveas(gcf, 'fig01_niveles_y_c_inv', 'pdf');

% --- Figura 2: Stock de capital ---
figure('Name', 'Stock de capital')
plot(T_muestra, ln_k(t0:t1), '-b', 'LineWidth', 2);
xlim([1954 2017]);
xlabel('Año');
ylabel('Log (nivel)');
title('Stock de capital — EE.UU. (1954–2016)');
leg = legend('Ln(Stock de Capital)');
set(leg, 'Location', 'SouthEast');
legend('boxoff');
grid on;
orient landscape;
saveas(gcf, 'fig02_nivel_capital', 'pdf');

% --- Figura 3: Mercado laboral y productividad ---
M_lab = [ln_h, ln_e, ln_w, ln_prod];
nombres_lab = {'Ln(Horas)', 'Ln(Empleo)', 'Ln(Salario Real)', 'Ln(Productividad)'};

figure('Name', 'Mercado laboral y productividad')
for j = 1:4
    subplot(2, 2, j)
    plot(T_muestra, M_lab(t0:t1, j), '-b', 'LineWidth', 2);
    title(nombres_lab{j});
    xlim([1954 2017]);
    grid on;
end
orient landscape;
saveas(gcf, 'fig03_niveles_mercado_laboral', 'pdf');

%% -----------------------------------------------------------------------
%  [3] Filtro Hodrick-Prescott (HP): separar tendencia y ciclo
%  -----------------------------------------------------------------------
%  IDEA:
%  Toda serie macroeconómica Y(t) se puede descomponer en:
%
%       Y(t) = Tendencia(t) + Ciclo(t)
%
%  La tendencia captura el crecimiento de largo plazo.
%  El ciclo captura las desviaciones transitorias respecto a ese trend.
%
%  El filtro HP obtiene la tendencia resolviendo el problema:
%
%    min  sum[ (Y_t - tau_t)^2 ] + lambda * sum[ (Delta^2 tau_t)^2 ]
%   {tau}
%
%  donde lambda controla el "suavizado" de la tendencia:
%    - lambda grande → tendencia muy suave (casi lineal)
%    - lambda chico  → tendencia se ajusta más a los datos
%
%  VALOR ESTÁNDAR:
%    lambda = 1600  para datos TRIMESTRALES  (Hodrick & Prescott, 1997)
%    lambda = 100   para datos ANUALES
%    lambda = 14400 para datos MENSUALES
%
%  LIMITACIÓN CONOCIDA:
%  El filtro HP tiene problemas en los extremos de la muestra (distorsiona
%  los últimos y primeros puntos). En la práctica se trabaja con muestras
%  largas y se interpreta con cautela los extremos.
%  -----------------------------------------------------------------------
lambda_q = 1600;   % Lambda para datos trimestrales

M_todas = [ln_y, ln_c, ln_inv, ln_k, ln_h, ln_e, ln_w, ln_prod];
nombres_todas = {'Ln(PIB)', 'Ln(Consumo)', 'Ln(Inversión)', 'Ln(Stock de Capital)', ...
                 'Ln(Horas)', 'Ln(Empleo)', 'Ln(Salario Real)', 'Ln(Productividad)'};
n_vars = size(M_todas, 2);

trend = zeros(length(T_muestra), n_vars);
cycle = zeros(length(T_muestra), n_vars);

for j = 1:n_vars
    [trend(:,j), cycle(:,j)] = hpfilter(M_todas(t0:t1, j), 'Smoothing', lambda_q);
end

fprintf('Filtro HP aplicado a %d variables con lambda = %d\n', n_vars, lambda_q);

%% -----------------------------------------------------------------------
%  [4] Gráficas: tendencia vs. nivel (para el PIB)
%  -----------------------------------------------------------------------
%  Esta gráfica es clave para mostrarle a los alumnos QUÉ hace el filtro:
%  la tendencia es la línea suave que "sigue" al PIB sin captar las
%  fluctuaciones de corto plazo.
%  -----------------------------------------------------------------------
figure('Name', 'PIB: nivel vs. tendencia HP')
plot(T_muestra, ln_y(t0:t1), '-b', ...
     T_muestra, trend(:,1), '--r', 'LineWidth', 1.8);
xlim([1953 2017]);
xlabel('Año');
ylabel('Log PIB real');
title('PIB real: nivel y tendencia HP — EE.UU.');
leg = legend('Ln(PIB)', 'Tendencia HP');
set(leg, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
legend('boxoff');
grid on;
orient landscape;
saveas(gcf, 'fig04_pib_tendencia_hp', 'pdf');

%% -----------------------------------------------------------------------
%  [5] Gráficas: componentes cíclicos
%  -----------------------------------------------------------------------
%  El componente cíclico mide la DESVIACIÓN PORCENTUAL del PIB (o de
%  cualquier variable) respecto a su tendencia. Como las series están en
%  logaritmo, cycle(:,j) ≈ (Y_t - tau_t) / tau_t × 100 en porcentaje.
%
%  Se grafica siempre junto al ciclo del PIB para ver la co-movimiento.
%  -----------------------------------------------------------------------

% --- Figura 5: Ciclos de Y, C, I, K ---
figure('Name', 'Componentes cíclicos: Y, C, I, K')

subplot(2, 2, 1)
plot(T_muestra, cycle(:,1), '-b', 'LineWidth', 1.5);
yline(0, '-k', 'LineWidth', 0.8);
xlim([1953 2017]);
title('Ciclo: Ln(PIB)');
xlabel('Año'); ylabel('Desviación del trend');
leg = legend('Ln(PIB)');
set(leg, 'Location', 'NorthEast'); legend('boxoff');
grid on;

for j = 2:4
    subplot(2, 2, j)
    plot(T_muestra, cycle(:,1), '--k', ...
         T_muestra, cycle(:,j), '-b', 'LineWidth', 1.5);
    yline(0, '-k', 'LineWidth', 0.8);
    xlim([1953 2017]);
    title(['Ciclo: ' nombres_todas{j}]);
    xlabel('Año'); ylabel('Desviación del trend');
    leg = legend('Ln(PIB)', nombres_todas{j});
    set(leg, 'Location', 'NorthEast'); legend('boxoff');
    grid on;
end

orient landscape;
saveas(gcf, 'fig05_ciclos_y_c_inv_k', 'pdf');

% --- Figura 6: Ciclos de H, E, W, Productividad ---
figure('Name', 'Componentes cíclicos: Horas, Empleo, Salario, Productividad')

for j = 5:8
    subplot(2, 2, j-4)
    plot(T_muestra, cycle(:,1), '--k', ...
         T_muestra, cycle(:,j), '-b', 'LineWidth', 1.5);
    yline(0, '-k', 'LineWidth', 0.8);
    xlim([1953 2017]);
    title(['Ciclo: ' nombres_todas{j}]);
    xlabel('Año'); ylabel('Desviación del trend');
    leg = legend('Ln(PIB)', nombres_todas{j});
    set(leg, 'Location', 'NorthEast'); legend('boxoff');
    grid on;
end

orient landscape;
saveas(gcf, 'fig06_ciclos_mercado_laboral', 'pdf');

%% -----------------------------------------------------------------------
%  [6] Estadísticos del componente cíclico
%  -----------------------------------------------------------------------
%  Calculamos los tres estadísticos canónicos de los hechos estilizados.
%  Referencia clásica: Kydland & Prescott (1982), Cooley & Prescott (1995).
%  -----------------------------------------------------------------------

% (a) Media (debería ser ~0 por construcción del filtro HP)
media = mean(cycle);

% (b) Desviación estándar y volatilidad relativa al PIB
desv_std         = std(cycle);
volatilidad_rel  = desv_std / desv_std(1);   % Relativa al PIB (primera columna)

% (c) Matriz de correlaciones (incluye todas las combinaciones)
%     La primera fila/columna da la correlación de cada variable con el PIB
correlacion = corrcoef(cycle);

% (d) Autocorrelación de orden 1 para cada variable
%     NOTA SINTAXIS: En MATLAB R2017b+ el segundo argumento de autocorr
%     debe pasarse como par nombre-valor: autocorr(x, 'NumLags', 1)
%     La versión antigua autocorr(x, 1) puede generar warnings en versiones
%     modernas de MATLAB.
autocorr_ciclo = zeros(1, n_vars);
for j = 1:n_vars
    ac = autocorr(cycle(:,j), 'NumLags', 1);
    autocorr_ciclo(j) = ac(2);   % ac(1) siempre es 1 (lag 0), ac(2) es lag 1
end

% --- Tabla resumen de hechos estilizados ---
fprintf('\n');
fprintf('================================================================\n');
fprintf('         HECHOS ESTILIZADOS — EE.UU. (1954 Q2 – 2016 Q1)       \n');
fprintf('================================================================\n');
fprintf('%-22s %10s %12s %12s %12s\n', ...
        'Variable', 'std(ciclo)', 'Volat. rel.', 'Corr(y,x)', 'Autocorr(1)');
fprintf('%s\n', repmat('-', 1, 70));
for j = 1:n_vars
    fprintf('%-22s %10.4f %12.4f %12.4f %12.4f\n', ...
            nombres_todas{j}, desv_std(j), volatilidad_rel(j), ...
            correlacion(1,j), autocorr_ciclo(j));
end
fprintf('================================================================\n');

%% -----------------------------------------------------------------------
%  [7] Correlaciones en ventanas móviles (rolling window)
%  -----------------------------------------------------------------------
%  MOTIVACIÓN:
%  Una correlación calculada sobre toda la muestra asume que la relación
%  entre las variables es ESTABLE en el tiempo. Pero esto puede no ser
%  cierto. Las correlaciones en ventanas móviles permiten ver cómo
%  evoluciona esa relación a lo largo del tiempo.
%
%  Resultado conocido: la correlación entre el ciclo del PIB y el de la
%  productividad laboral CAYÓ desde los años 80. Esto genera debate sobre
%  el rol de los shocks de tecnología en el ciclo (Hansen, 1985;
%  Galí, 1999).
%  -----------------------------------------------------------------------

% Correlación entre ciclo del PIB y ciclo de la Productividad
% Punto de partida: 1980 Q4 → índice 108 dentro de la muestra analizada
% (1954 Q2 + 108 trimestres = 1954.25 + 27 = 1981.25... aprox 1980 Q4)
idx_1980q4 = 108;

% Expandimos la ventana de 4 en 4 trimestres (un año a la vez)
corr_pib_prod = [];
for j = 0:35
    aux = corrcoef(cycle(1:idx_1980q4 + j*4, 1), ...
                   cycle(1:idx_1980q4 + j*4, 8));
    corr_pib_prod = [corr_pib_prod; aux(1,2)];
end
fechas_rolling = T_muestra(idx_1980q4 : 4 : idx_1980q4 + 35*4);

% Correlación entre ciclo del PIB y ciclo de las Horas
corr_pib_horas = [];
for j = 0:35
    aux = corrcoef(cycle(1:idx_1980q4 + j*4, 1), ...
                   cycle(1:idx_1980q4 + j*4, 5));
    corr_pib_horas = [corr_pib_horas; aux(1,2)];
end

% Correlación entre ciclo del PIB y ciclo del Empleo
corr_pib_empleo = [];
for j = 0:35
    aux = corrcoef(cycle(1:idx_1980q4 + j*4, 1), ...
                   cycle(1:idx_1980q4 + j*4, 6));
    corr_pib_empleo = [corr_pib_empleo; aux(1,2)];
end

% --- Figura 7: Correlaciones en ventana móvil ---
figure('Name', 'Correlaciones rolling: PIB vs. Productividad, Horas, Empleo')

subplot(2, 1, 1)
plot(fechas_rolling, corr_pib_prod, '-b', 'LineWidth', 2);
yline(0, '--k', 'LineWidth', 0.8);
xlim([1980 2010]);
ylim([-0.2 1]);
xlabel('Año (fin de ventana)');
ylabel('Correlación');
title('Correlación entre ciclo del PIB y ciclo de la Productividad (ventana móvil)');
legend('corr(y, prod)', 'Location', 'SouthWest');
legend('boxoff');
grid on;

subplot(2, 1, 2)
plot(fechas_rolling, corr_pib_horas,  '-b', ...
     fechas_rolling, corr_pib_empleo, '--r', 'LineWidth', 2);
yline(0, '-k', 'LineWidth', 0.8);
xlim([1980 2010]);
xlabel('Año (fin de ventana)');
ylabel('Correlación');
title('Correlación entre ciclo del PIB y ciclo de Horas/Empleo (ventana móvil)');
leg = legend('corr(y, horas)', 'corr(y, empleo)');
set(leg, 'Location', 'SouthEast'); legend('boxoff');
grid on;

orient landscape;
saveas(gcf, 'fig07_correlaciones_rolling', 'pdf');

%% -----------------------------------------------------------------------
%  [8] Análisis con datos ANUALES: PIB y PTF (Productividad Total de los
%      Factores)
%  -----------------------------------------------------------------------
%  La PTF (o TFP en inglés) mide el residuo de Solow: cuánto del
%  crecimiento del PIB no se explica por acumulación de capital ni de
%  trabajo. Es una medida del "progreso tecnológico" o de la eficiencia
%  global de la economía.
%
%  NOTA SOBRE LAMBDA:
%  Como estos datos son ANUALES (no trimestrales), se usa lambda = 100.
%  Usar lambda = 1600 con datos anuales suavizaría demasiado la tendencia
%  y distorsionaría el componente cíclico.
%
%  NOTA DE DISPONIBILIDAD:
%  PBI_TFP_anual.mat contiene:
%    - Columna 1: PIB real en niveles (en billones de USD de 2009)
%    - Columna 2: PTF (índice, de mfp_tables_historical.xlsx del BLS)
%    - Período: 1948–2015 (datos anuales)
%
%  Si este archivo no está disponible, comentar esta sección.
%  -----------------------------------------------------------------------
if isfile('PBI_TFP_anual.mat')
    load PBI_TFP_anual.mat;

    %  CORRECCIÓN IMPORTANTE:
    %  La columna del PIB está en billones de USD, hay que convertir a USD
    %  antes de tomar logaritmo (multiplicar por 10^9).
    ln_PBI_anual = log(PBI_TFP_anual(:,1) * 1e9);
    ln_PTF_anual = log(PBI_TFP_anual(:,2));
    datos_anuales = [ln_PBI_anual, ln_PTF_anual];

    %  Lambda = 100 para datos anuales
    lambda_a = 100;
    [trend_anual, ciclo_anual] = hpfilter(datos_anuales, 'Smoothing', lambda_a);

    tiempo_anual = 1948:2015;

    % --- Figura 8: Ciclos del PIB y PTF (datos anuales) ---
    figure('Name', 'Ciclos PIB y PTF (datos anuales)')
    plot(tiempo_anual, ciclo_anual(:,1), '-r', ...
         tiempo_anual, ciclo_anual(:,2), '--b', 'LineWidth', 1.8);
    yline(0, '-k', 'LineWidth', 0.8);
    xlim([1947 2016]);
    xlabel('Año');
    ylabel('Desviación del trend');
    title('Ciclos del PIB y la PTF — EE.UU. (1948–2015, datos anuales)');
    leg = legend('Ciclo del PIB', 'Ciclo de la PTF');
    set(leg, 'Location', 'North', 'Orientation', 'Horizontal');
    legend('boxoff');
    grid on;
    orient landscape;
    saveas(gcf, 'fig08_ciclos_pib_ptf_anual', 'pdf');

    % --- Estadísticos PTF/PIB (anuales) ---
    desv_std_anual  = std(ciclo_anual);
    corr_anual      = corrcoef(ciclo_anual);
    ac_pib_anual    = autocorr(ciclo_anual(:,1), 'NumLags', 1);
    ac_ptf_anual    = autocorr(ciclo_anual(:,2), 'NumLags', 1);

    fprintf('\n--- Estadísticos anuales: PIB y PTF ---\n');
    fprintf('%-20s %10s %12s %12s\n', 'Variable', 'std(ciclo)', 'Corr(PIB,x)', 'Autocorr(1)');
    fprintf('%s\n', repmat('-', 1, 58));
    fprintf('%-20s %10.4f %12.4f %12.4f\n', 'PIB (anual)',  desv_std_anual(1), corr_anual(1,1), ac_pib_anual(2));
    fprintf('%-20s %10.4f %12.4f %12.4f\n', 'PTF (anual)',  desv_std_anual(2), corr_anual(1,2), ac_ptf_anual(2));

else
    fprintf('\nARCHIVO NO ENCONTRADO: PBI_TFP_anual.mat\n');
    fprintf('Para el análisis de PTF, asegurate de tener ese archivo en la carpeta.\n');
end

%% -----------------------------------------------------------------------
%  [9] Mensaje final
%  -----------------------------------------------------------------------
fprintf('\n================================================================\n');
fprintf('Script 01 completado. Figuras guardadas como PDF en la carpeta.\n');
fprintf('================================================================\n');
