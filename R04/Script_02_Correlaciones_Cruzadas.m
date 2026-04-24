%% Script 02: Correlaciones cruzadas con rezagos (lead/lag analysis)
%{
-----------------------------------------------------------------------
Autor    : Alejandro Ventura
Curso    : Macroeconomía II
Fecha    : 2026
-----------------------------------------------------------------------
PROPÓSITO
    Este script calcula y grafica las correlaciones cruzadas entre el
    componente cíclico del PIB y el de cada variable macroeconómica,
    para rezagos y adelantos de hasta 8 trimestres (2 años).

    Esto permite clasificar cada variable como:
      - Indicador LÍDER    : se mueve ANTES que el PIB
      - Indicador COINCIDENTE: se mueve AL MISMO TIEMPO que el PIB
      - Indicador REZAGADO : se mueve DESPUÉS que el PIB

CONCEPTO CLAVE: ¿Qué es la correlación cruzada en k?

    rho(k) = corr( ciclo_PIB(t) , ciclo_X(t + k) )

    Interpretación:
      k > 0  →  X se adelanta al PIB  (X es LÍDER)
      k = 0  →  X se mueve junto al PIB (COINCIDENTE)
      k < 0  →  X se rezaga al PIB    (X es REZAGADO)

    Ejemplo: si rho(k) alcanza su máximo en k = +2, significa que
    X en t+2 está más correlacionada con el PIB en t → X se mueve
    2 trimestres ANTES que el PIB.

    ATENCIÓN AL SIGNO: si la correlación contemporánea (k=0) es
    negativa (variable contracíclica), buscamos el MÍNIMO en vez
    del máximo para identificar el rezago relevante.

REFERENCIA:
    Cooley & Prescott (1995), "Economic Growth and Business Cycles",
    en Cooley (ed.), Frontiers of Business Cycle Research.
    Kydland & Prescott (1990), "Business Cycles: Real Facts and a
    Monetary Myth", Federal Reserve Bank of Minneapolis Quarterly Review.

REQUISITO PREVIO:
    Haber corrido Script_00 y Script_01. Este script retoma el trabajo
    donde lo dejó Script_01: carga los datos y recalcula los ciclos.
-----------------------------------------------------------------------
%}

%% -----------------------------------------------------------------------
%  [0] Limpieza del entorno
%  -----------------------------------------------------------------------
clear all
clc
close all

%% -----------------------------------------------------------------------
%  [1] Carga de datos y cálculo del ciclo HP
%  -----------------------------------------------------------------------
%  Repetimos los pasos de Script_01 para tener el workspace listo.
%  Si ya corriste Script_01 en la misma sesión, podés comentar esta
%  sección y las variables ya estarán disponibles.
%  -----------------------------------------------------------------------
load data_matlab_agregada.mat;

% Renombre a nombres cortos
ln_y    = ln_gdp;
ln_c    = ln_consumo_real;
ln_inv  = ln_inv_privada_real_bd;
ln_k    = ln_stock_capital;
ln_h    = ln_horas_total_nonfarm;
ln_e    = ln_empleo_total_nonfarm;
ln_w    = ln_salario_real_porhora;
ln_prod = ln_productividad;

clear ln_gdp ln_consumo_real ln_inv_privada_real_bd ln_stock_capital ...
      ln_horas_total_nonfarm ln_empleo_total_nonfarm ...
      ln_salario_real_porhora ln_productividad;

% Período de análisis
t0 = 30;    % 1954 Q2
t1 = 277;   % 2016 Q1
T_muestra = Fecha(t0:t1);

% Filtro HP (lambda = 1600 para datos trimestrales)
lambda_q = 1600;
M_todas  = [ln_y, ln_c, ln_inv, ln_k, ln_h, ln_e, ln_w, ln_prod];
nombres  = {'Ln(PIB)', 'Ln(Consumo)', 'Ln(Inversión)', 'Ln(Stock de Capital)', ...
            'Ln(Horas)', 'Ln(Empleo)', 'Ln(Salario Real)', 'Ln(Productividad)'};
n_vars   = size(M_todas, 2);

trend = zeros(length(T_muestra), n_vars);
cycle = zeros(length(T_muestra), n_vars);
for j = 1:n_vars
    [trend(:,j), cycle(:,j)] = hpfilter(M_todas(t0:t1, j), 'Smoothing', lambda_q);
end

fprintf('Datos y ciclos cargados. %d variables, %d trimestres.\n', n_vars, length(T_muestra));

%% -----------------------------------------------------------------------
%  [2] Cálculo de correlaciones cruzadas
%  -----------------------------------------------------------------------
%  Para cada variable X y para cada rezago k en [-max_lag, +max_lag],
%  calculamos:
%
%       rho(k) = corr( ciclo_PIB(t) , ciclo_X(t+k) )
%
%  Lo hacemos con un bucle explícito para que quede claro qué se está
%  computando. Esto es equivalente a xcorr normalizada pero más
%  transparente pedagógicamente.
%  -----------------------------------------------------------------------
max_lag = 8;   % ±8 trimestres = ±2 años
lags    = -max_lag : max_lag;   % vector de rezagos: -8, -7, ..., 0, ..., 7, 8
n_lags  = length(lags);
T       = length(T_muestra);

% Matriz de correlaciones cruzadas: filas = rezagos, columnas = variables
CC = zeros(n_lags, n_vars);

ciclo_pib = cycle(:, 1);   % ciclo del PIB (columna de referencia)

for j = 1:n_vars
    ciclo_x = cycle(:, j);
    for idx_k = 1:n_lags
        k = lags(idx_k);
        if k > 0
            % X adelantada k períodos respecto al PIB
            % corr( PIB(t) , X(t+k) ) → usamos observaciones solapadas
            cc = corrcoef(ciclo_pib(1:T-k), ciclo_x(1+k:T));
        elseif k < 0
            % X rezagada |k| períodos respecto al PIB
            % corr( PIB(t) , X(t+k) ) → equivalente a corr( PIB(t+|k|) , X(t) )
            cc = corrcoef(ciclo_pib(1-k:T), ciclo_x(1:T+k));
        else
            % k = 0: correlación contemporánea
            cc = corrcoef(ciclo_pib, ciclo_x);
        end
        CC(idx_k, j) = cc(1, 2);
    end
end

fprintf('Correlaciones cruzadas calculadas para rezagos %d a +%d trimestres.\n', -max_lag, max_lag);

%% -----------------------------------------------------------------------
%  [3] Tabla resumen: clasificación de indicadores
%  -----------------------------------------------------------------------
%  Para cada variable identificamos:
%   - La correlación contemporánea (k=0)
%   - El rezago donde la correlación (en valor absoluto) es máxima
%   - La clasificación: LÍDER, COINCIDENTE o REZAGADO
%
%  Criterio de clasificación:
%   Si el máximo |rho| está en k > +1  →  LÍDER     (X se adelanta al PIB)
%   Si el máximo |rho| está en k ∈ [-1,+1] →  COINCIDENTE
%   Si el máximo |rho| está en k < -1  →  REZAGADO  (X se rezaga al PIB)
%  -----------------------------------------------------------------------
idx_k0 = find(lags == 0);   % índice correspondiente a k=0 en el vector de rezagos

fprintf('\n');
fprintf('====================================================================\n');
fprintf('   CLASIFICACIÓN DE INDICADORES DEL CICLO — EE.UU. (1954–2016)    \n');
fprintf('====================================================================\n');
fprintf('%-24s %10s %10s %12s %14s\n', ...
        'Variable', 'Corr(k=0)', 'Lag óptimo', 'Corr(opt.)', 'Tipo');
fprintf('%s\n', repmat('-', 1, 72));

tipo_indicador = cell(n_vars, 1);
lag_optimo     = zeros(n_vars, 1);
corr_optima    = zeros(n_vars, 1);

for j = 1:n_vars
    corr_k0   = CC(idx_k0, j);
    [~, idx_max] = max(abs(CC(:, j)));
    k_opt     = lags(idx_max);
    rho_opt   = CC(idx_max, j);

    lag_optimo(j)  = k_opt;
    corr_optima(j) = rho_opt;

    if k_opt > 1
        tipo = 'LIDER';
    elseif k_opt < -1
        tipo = 'REZAGADO';
    else
        tipo = 'COINCIDENTE';
    end
    tipo_indicador{j} = tipo;

    fprintf('%-24s %10.4f %10d %12.4f %14s\n', ...
            nombres{j}, corr_k0, k_opt, rho_opt, tipo);
end
fprintf('====================================================================\n');
fprintf('Nota: k > 0 = X se adelanta al PIB (líder); k < 0 = X se rezaga.\n');
fprintf('      Umbral de clasificación: |k| > 1 trimestre.\n');

%% -----------------------------------------------------------------------
%  [4] Gráficas de correlaciones cruzadas
%  -----------------------------------------------------------------------
%  Graficamos la función de correlación cruzada para cada variable.
%  El eje x son los rezagos k; el eje y es rho(k).
%  La línea vertical punteada marca k=0 (contemporáneo).
%  -----------------------------------------------------------------------

% --- Figura 1: Y, C, I, K ---
figure('Name', 'Correlaciones cruzadas: Y, C, I, K')
for j = 1:4
    subplot(2, 2, j)
    bar(lags, CC(:, j), 'FaceColor', [0.2 0.4 0.7], 'EdgeColor', 'none');
    hold on;
    xline(0, '--k', 'LineWidth', 1.2);
    yline(0, '-k', 'LineWidth', 0.8);
    xlim([-max_lag-0.5, max_lag+0.5]);
    ylim([-1 1]);
    xlabel('Rezago k (trimestres)');
    ylabel('Correlación');
    title(['corr( PIB(t), ' nombres{j} '(t+k) )']);
    grid on;
    hold off;
end
orient landscape;
saveas(gcf, 'fig09_cc_y_c_inv_k', 'pdf');

% --- Figura 2: Horas, Empleo, Salario, Productividad ---
figure('Name', 'Correlaciones cruzadas: Horas, Empleo, Salario, Productividad')
for j = 5:8
    subplot(2, 2, j-4)
    bar(lags, CC(:, j), 'FaceColor', [0.2 0.4 0.7], 'EdgeColor', 'none');
    hold on;
    xline(0, '--k', 'LineWidth', 1.2);
    yline(0, '-k', 'LineWidth', 0.8);
    xlim([-max_lag-0.5, max_lag+0.5]);
    ylim([-1 1]);
    xlabel('Rezago k (trimestres)');
    ylabel('Correlación');
    title(['corr( PIB(t), ' nombres{j} '(t+k) )']);
    grid on;
    hold off;
end
orient landscape;
saveas(gcf, 'fig10_cc_laboral_prod', 'pdf');

% --- Figura 3: Panel compacto con todas las variables (excluyendo PIB) ---
%  Útil para comparar visualmente en clase con una sola imagen.
figure('Name', 'Panel: correlaciones cruzadas — todas las variables vs. PIB')
colores = lines(n_vars - 1);
for j = 2:n_vars
    subplot(2, ceil((n_vars-1)/2), j-1)
    bar(lags, CC(:, j), 'FaceColor', colores(j-1,:), 'EdgeColor', 'none');
    hold on;
    xline(0, '--k', 'LineWidth', 1.2);
    yline(0, '-k', 'LineWidth', 0.8);
    xlim([-max_lag-0.5, max_lag+0.5]);
    ylim([-1 1]);
    xlabel('k');
    ylabel('\rho(k)');
    title(nombres{j}, 'FontSize', 9);
    grid on;
    hold off;
end
sgtitle('corr( ciclo_{PIB}(t) ,  ciclo_X(t+k) ) — EE.UU. (1954–2016)', ...
        'FontSize', 10, 'FontWeight', 'bold');
orient landscape;
saveas(gcf, 'fig11_cc_panel_completo', 'pdf');

%% -----------------------------------------------------------------------
%  [5] Mensaje final
%  -----------------------------------------------------------------------
fprintf('\n====================================================================\n');
fprintf('Script 02 completado. Figuras guardadas como PDF en la carpeta.\n');
fprintf('  fig09_cc_y_c_inv_k.pdf\n');
fprintf('  fig10_cc_laboral_prod.pdf\n');
fprintf('  fig11_cc_panel_completo.pdf\n');
fprintf('====================================================================\n');
