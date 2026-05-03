// miu_4e_repaso.mod
// Basado en miu_4e.dyn — Walsh, Monetary Theory and Policy, 4th ed.
// ----------------------------------------------------------------
// MODIFICACION PARA REPASO:
// Se conserva intacto el codigo original de Walsh.
// Al final se agrega una seccion de analisis de estado estacionario
// que varia THETA y registra como responden las variables reales
// versus las nominales. Observa los graficos y reflexiona:
//   --> ¿Cuales variables cambian con THETA? ¿Cuales no?
//   --> ¿Que implica eso sobre la estructura del modelo?
// ----------------------------------------------------------------

var Z U Y C K INV N R M I MUC PI;

varexo EPZ EPU;

parameters A B ALPHA BETA ETA DELTA GAMMA OMEGA1 OMEGA2 SIGMA_Z SIGMA_M SIGMA_V;
parameters RHOZ RHOU THETA PHI UPSILON phi NSS YK CK NKSS KSS CSS RSS ISS MSS XSS;
ALPHA = 0.36;
DELTA = 0.019;
BETA  = 0.989;
ETA   = 1;
THETA = 1.0138;

PHI = 2;
B   = 9;

NSS = 1/3;

// Implied parameters
YK    = (1/ALPHA)*((1/BETA) - 1 + DELTA);
CK    = YK - DELTA;
NKSS  = (YK)^(1/(1-ALPHA));
KSS   = NSS/NKSS;
CSS   = CK*KSS;
RSS   = 1/BETA;
ISS   = (RSS*THETA - 1);
UPSILON = ISS/(1+ISS);

A   = 1/(1 + UPSILON*(0.7811^B));
MSS = CSS*((A*UPSILON)/(1-A))^(-1/B);
XSS = A*(CSS^(1-B)) + (1-A)*(MSS^(1-B));
GAMMA  = A*(CSS^(1-B))/XSS;
OMEGA1 = (B - PHI)*GAMMA - B;
OMEGA2 = (B - PHI)*(1-GAMMA);

SIGMA_Z = 0.34;
RHOZ    = 0.95;
RHOU    = 0.69;
phi     = 0;
SIGMA_M = 1.17;
SIGMA_V = ((1-RHOU^2)*(SIGMA_M)^2 - ((phi^2)/(1-RHOZ^2))*(SIGMA_Z^2))^.5;

model(linear);
    Z   = RHOZ*Z(-1) + EPZ;
    U   = RHOU*U(-1) + phi*Z(-1) + EPU;
    Y   = ALPHA*K(-1) + (1-ALPHA)*N + Z;
    YK*Y = CK*C + DELTA*INV;
    K   = (1 - DELTA)*K(-1) + DELTA*INV;
    (1 + (ETA*NSS/(1-NSS)))*N = Y + MUC;
    R   = ALPHA*YK*(Y(+1) - K);
    MUC = OMEGA1*C + OMEGA2*M;
    MUC = R + MUC(+1);
    M   = C - (1/B)*((1-ISS)/ISS)*I;
    M   = M(-1) + U - PI;
    I   = R + PI(+1);
end;

steady;
check;

shocks;
var EPZ;
stderr SIGMA_Z;
var EPU;
stderr SIGMA_V;
end;

stoch_simul(order=1,ar=1,irf=60,graph,print);
OOPT.MODELS.MIU_1 = oo_;
save OOPT_MIU_1;

% ================================================================
% SECCION DE REPASO: ESTADO ESTACIONARIO vs. THETA
% ================================================================
% El modelo linearizado de arriba analiza DESVIACIONES respecto al
% estado estacionario. Esta seccion calcula directamente ese estado
% estacionario para distintos valores de THETA (tasa de crecimiento
% del dinero) usando las mismas formulas de calibracion del modelo.
%
% Pregunta guia: si la tasa de crecimiento del dinero sube de forma
% permanente (THETA aumenta), ¿que le ocurre a C, K, N, Y en el
% largo plazo? ¿Y a la tasa nominal i y a los saldos reales m?
%
% Nota: en el modelo MIU con utilidad separable, la condicion de
% Euler para el capital es:
%       1/beta = 1 + MPK - delta
% Esta condicion NO involucra dinero ni inflacion. ¿Que implica eso?
% ================================================================

THETA_grid = 1.000 : 0.002 : 1.100;   % Theta desde 0% hasta ~10% trimestral
n_th = length(THETA_grid);

% Pre-alocar vectores de resultados
CSS_vec = zeros(1, n_th);   % Consumo en SS
KSS_vec = zeros(1, n_th);   % Capital en SS
YSS_vec = zeros(1, n_th);   % Producto en SS  (= YK * KSS aprox)
ISS_vec = zeros(1, n_th);   % Tasa nominal en SS
MSS_vec = zeros(1, n_th);   % Saldos reales en SS

for jj = 1:n_th
    th = THETA_grid(jj);

    % --- Variables REALES ---
    % (Mismas formulas que la calibracion de arriba; notar que
    %  YK, CK, NKSS, KSS, CSS dependen solo de ALPHA, BETA, DELTA, NSS)
    YK_j    = (1/ALPHA)*((1/BETA) - 1 + DELTA);
    CK_j    = YK_j - DELTA;
    NKSS_j  = YK_j^(1/(1-ALPHA));
    KSS_j   = NSS / NKSS_j;
    CSS_j   = CK_j * KSS_j;
    YSS_j   = YK_j * KSS_j;       % Y/K * K = Y

    % --- Variables NOMINALES ---
    % (Aqui aparece th = THETA)
    RSS_j     = 1/BETA;
    ISS_j     = RSS_j * th - 1;          % Fisher en SS: i = r*theta - 1
    UPSILON_j = ISS_j / (1 + ISS_j);
    A_j       = 1 / (1 + UPSILON_j * (0.7811^B));
    MSS_j     = CSS_j * ((A_j * UPSILON_j) / (1 - A_j))^(-1/B);

    CSS_vec(jj) = CSS_j;
    KSS_vec(jj) = KSS_j;
    YSS_vec(jj) = YSS_j;
    ISS_vec(jj) = ISS_j;
    MSS_vec(jj) = MSS_j;
end

% ---- Graficos ----
figure('Name', 'MIU: Estado Estacionario vs. Crecimiento del Dinero (THETA)');

subplot(2,3,1);
plot(THETA_grid, CSS_vec, 'b-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('C_{ss}');
title('Consumo (real)');

subplot(2,3,2);
plot(THETA_grid, KSS_vec, 'b-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('K_{ss}');
title('Capital (real)');

subplot(2,3,3);
plot(THETA_grid, YSS_vec, 'b-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('Y_{ss}');
title('Producto (real)');

subplot(2,3,4);
plot(THETA_grid, ISS_vec, 'r-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('i_{ss}');
title('Tasa nominal');

subplot(2,3,5);
plot(THETA_grid, MSS_vec, 'r-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('m_{ss}');
title('Saldos reales de dinero');

subplot(2,3,6);
axis off;
text(0.05, 0.7, 'Variables en azul: reales', 'FontSize', 11, 'Color', 'blue');
text(0.05, 0.5, 'Variables en rojo: nominales', 'FontSize', 11, 'Color', 'red');
text(0.05, 0.25, ['Pregunta: ¿que observas', char(10), ...
                  'sobre la pendiente de', char(10), ...
                  'cada curva?'], 'FontSize', 10);

sgtitle('Modelo MIU (Walsh Cap. 2): Variables de Estado Estacionario ante cambios en \Theta');

% Imprimir tabla resumen
fprintf('\n--- MODELO MIU: Estado Estacionario ---\n');
fprintf('%8s  %8s  %8s  %8s  %8s  %8s\n', 'THETA','C_ss','K_ss','Y_ss','i_ss','m_ss');
fprintf('%s\n', repmat('-',1,56));
idx_print = round(linspace(1, n_th, 6));
for jj = idx_print
    fprintf('%8.4f  %8.6f  %8.6f  %8.6f  %8.6f  %8.6f\n', ...
        THETA_grid(jj), CSS_vec(jj), KSS_vec(jj), YSS_vec(jj), ...
        ISS_vec(jj), MSS_vec(jj));
end
fprintf('\nOmega2 = %.4f  (parametro de no-separabilidad)\n', OMEGA2);
fprintf('Si Omega2 = 0, el dinero no afecta MUC y la separabilidad es exacta.\n');
