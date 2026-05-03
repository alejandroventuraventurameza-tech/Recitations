// cia_4e_repaso.mod
// Basado en cia_4e.dyn — Walsh, Monetary Theory and Policy, 4th ed.
// ----------------------------------------------------------------
// MODIFICACION PARA REPASO:
// Se conserva intacto el codigo original de Walsh.
// Al final se agrega una seccion que calcula el estado estacionario
// ANALITICO del modelo CIA para distintos valores de THETA.
//
// En el modelo CIA, la restriccion de cash-in-advance implica que
// el hogar necesita dinero para comprar consumo. Esto hace que la
// tasa nominal i entre directamente en la condicion de optimalidad
// laboral. Observa los graficos y reflexiona:
//   --> ¿Cuales variables cambian con THETA en este modelo?
//   --> ¿Como se compara eso con lo que viste en el modelo MIU?
//   --> ¿Que ecuacion del modelo CIA es la "culpable"?
// ----------------------------------------------------------------
// Model formulation (c) 2010, 2016 Carl E. Walsh
// ----------------------------------------------------------------

var Y K N C INV MUY R I PI M U Z;

varexo EPZ EPU;

parameters ALPHA BETA YK CK RSS DELTA ETA B ISS;
parameters RHOZ RHOU THETA PHI phi NSS SIGMA_U SIGMA_Z SIGMA_M;
ALPHA = 0.36;
DELTA = 0.019;
BETA  = 0.989;
ETA   = 1;
THETA = 1.0138;
SIGMA = 1;
PHI   = 2;
B     = 9;
phi   = 0;
YK    = (1/ALPHA)*((1/BETA) - 1 + DELTA);
CK    = YK - DELTA;

RSS = 1/BETA;
ISS = RSS*THETA;

NSS = 1/3;

RHOZ    = 0.9;
RHOU    = 0.67;
SIGMA_Z = 0.34;
SIGMA_M = 1.17;
SIGMA_U = ((1-RHOU^2)*(SIGMA_M)^2 - ((phi^2)/(1-RHOZ^2))*(SIGMA_Z^2))^.5;

model(linear);
    Z    = RHOZ*Z(-1) + EPZ;
    U    = RHOU*U(-1) + phi*Z(-1) + EPU;
    Y    = ALPHA*K(-1) + (1-ALPHA)*N + Z;
    YK*Y = CK*C + DELTA*INV;
    K    = (1-DELTA)*K(-1) + DELTA*INV;
    R    = ALPHA*YK*(Y(+1) - K);
    Y    = (1 + (ETA*NSS/(1-NSS)))*N - MUY;
    MUY  = MUY(+1) + R;
    MUY  = -PHI*C - I;        % <-- ECUACION CLAVE: i entra en MUY
    M    = C;                  % <-- Restriccion CIA: m = c
    M    = M(-1) + U - PI;
    I    = R + PI(+1);
end;

steady;
check;

shocks;
var EPZ;
stderr SIGMA_Z;
var EPU;
stderr SIGMA_U;
end;

stoch_simul(order=1,ar=1,irf=60,nograph,print);
OOPT.MODELS.CIA1 = oo_;
save OOPT_CIA1;

phi = -0.5;
stoch_simul(order=1,ar=1,irf=60,nograph,print);
OOPT.MODELS.CIA2 = oo_;
save OOPT_CIA2;

phi = 0.5;
stoch_simul(order=1,ar=1,irf=60,nograph,print);
OOPT.MODELS.CIA3 = oo_;
save OOPT_CIA3;

RHOU = 0.9;
phi  = 0;
stoch_simul(order=1,ar=1,irf=60,nograph,noprint);
OOPT.MODELS.CIA4 = oo_;
save OOPT_CIA4;

OOPT.NN=40;
OOPT.plot_color={'k' 'b:' 'r-.'};
OOPT.shocks_names={'EPZ'};
OOPT.tit_shocks={'Productivity Shock'};
OOPT.type_models={'CIA2' 'CIA1' 'CIA3'};
OOPT.legend_models={'\phi = -0.5' '\phi = 0' '\phi = 0.5'};
OOPT.list_endo={'Y' 'N' 'R' 'I' 'PI' 'M'};
OOPT.label_variables={'Output' 'Employment' 'Real Interest Rate' 'Nominal Interest Rate' 'Inflation Rate' 'Real Money Supply'};
plot_comp(OOPT);
print -depsc2 'Ch3_Figure2'

OOPT.NN=40;
OOPT.plot_color={'b' 'r:'};
OOPT.shocks_names={'EPU'};
OOPT.tit_shocks={'Policy Shock'};
OOPT.type_models={'CIA1' 'CIA4'};
OOPT.legend_models={'\rho_u = 0.67' '\rho_u = 0.9'};
OOPT.list_endo={'Y' 'N' 'R' 'I' 'PI' 'M'};
OOPT.label_variables={'Output' 'Employment' 'Real Interest Rate' 'Nominal Interest Rate' 'Inflation Rate' 'Real Money Supply'};
plot_comp(OOPT);
print -depsc2 'Ch3_Figure1'

% ================================================================
% SECCION DE REPASO: ESTADO ESTACIONARIO ANALITICO vs. THETA
% ================================================================
% El modelo CIA en estado estacionario (version no linealizada)
% satisface las siguientes condiciones estructurales:
%
%  (1) Euler para capital:  MPK = 1/beta - 1 + delta  [no depende de THETA]
%      => ratio K/Y = alpha / (1/beta - 1 + delta)    [fijo]
%      => ratio C/Y = 1 - delta*(K/Y)  =: psi          [fijo]
%
%  (2) Fisher en SS:        (1+i) = (1/beta)*THETA     [depende de THETA]
%
%  (3) Optimalidad laboral con restriccion CIA:
%      MPN = (1+i) * MRS_{c,l}
%      Es decir: la inflacion crea una DISTORSION sobre la decision trabajo-ocio.
%      Con utilidad logaritmica en consumo y ocio:
%        (1-alpha)*Y/N = (1+i) * chi * C / (1-N)
%      => N_ss = (1-alpha) / [ (1-alpha) + chi*(1+i)*psi ]
%
%      donde chi se calibra para que N_ss = 1/3 al THETA de referencia.
%
% Pregunta guia: ¿por que en el CIA la ecuacion (3) involucra (1+i)?
% ¿Que ecuacion del modelo linealizado de arriba captura eso?
% (Pista: MUY = -PHI*C - I)
% ================================================================

% --- Parametros estructurales ---
alpha_ = ALPHA;
beta_  = BETA;
delta_ = DELTA;

% Ratios de estado estacionario (independientes de THETA)
phi_ss = 1/beta_ - 1 + delta_;          % = YK: rendimiento neto del capital
psi    = (phi_ss - delta_) / phi_ss;    % = CK/YK: ratio C/Y en SS
kn_ratio = (alpha_ / phi_ss)^(1/(1-alpha_));  % ratio K/N (independiente de THETA)
yn_ratio = kn_ratio^alpha_;                    % ratio Y/N (independiente de THETA)

% --- Calibrar chi para que N_ss = 1/3 al THETA de referencia ---
i_base    = THETA / beta_ - 1;               % tasa nominal neta en SS de referencia
chi_calib = (1-alpha_) * (1-NSS) / (NSS * (1+i_base) * psi);
% Verificacion: N_check deberia ser = NSS = 1/3
N_check = (1-alpha_) / ((1-alpha_) + chi_calib*(1+i_base)*psi);
fprintf('\nVerificacion calibracion CIA: N_ss(THETA_base) = %.4f  (objetivo: %.4f)\n', ...
        N_check, NSS);

% --- Grilla de THETA ---
THETA_grid = 1.000 : 0.002 : 1.100;
n_th = length(THETA_grid);

N_cia = zeros(1, n_th);
K_cia = zeros(1, n_th);
Y_cia = zeros(1, n_th);
C_cia = zeros(1, n_th);
I_cia = zeros(1, n_th);

for jj = 1:n_th
    th   = THETA_grid(jj);
    i_ss = th / beta_ - 1;               % Fisher: i cambia con THETA
    I_cia(jj) = i_ss;

    % Optimalidad laboral con distorsion CIA
    N_cia(jj) = (1-alpha_) / ((1-alpha_) + chi_calib*(1+i_ss)*psi);

    % El resto del estado estacionario escala con N
    K_cia(jj) = kn_ratio * N_cia(jj);
    Y_cia(jj) = yn_ratio * N_cia(jj);
    C_cia(jj) = psi * Y_cia(jj);
end

% ---- Graficos ----
figure('Name', 'CIA: Estado Estacionario vs. Crecimiento del Dinero (THETA)');

subplot(2,3,1);
plot(THETA_grid, C_cia, 'b-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('C_{ss}');
title('Consumo (real)');

subplot(2,3,2);
plot(THETA_grid, N_cia, 'b-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('N_{ss}');
title('Trabajo (real)');

subplot(2,3,3);
plot(THETA_grid, Y_cia, 'b-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('Y_{ss}');
title('Producto (real)');

subplot(2,3,4);
plot(THETA_grid, K_cia, 'b-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('K_{ss}');
title('Capital (real)');

subplot(2,3,5);
plot(THETA_grid, I_cia, 'r-', 'LineWidth', 2); grid on;
xlabel('\Theta'); ylabel('i_{ss}');
title('Tasa nominal');

subplot(2,3,6);
axis off;
text(0.05, 0.75, 'Variables en azul: reales', 'FontSize', 11, 'Color', 'blue');
text(0.05, 0.55, 'Variables en rojo: nominales', 'FontSize', 11, 'Color', 'red');
text(0.05, 0.30, ['Pregunta: ¿que observas', char(10), ...
                  'sobre la pendiente de', char(10), ...
                  'las curvas azules?', char(10), ...
                  '¿Igual o diferente al MIU?'], 'FontSize', 10);

sgtitle('Modelo CIA (Walsh Cap. 3): Variables de Estado Estacionario ante cambios en \Theta');

% Imprimir tabla resumen
fprintf('\n--- MODELO CIA: Estado Estacionario Analitico ---\n');
fprintf('%8s  %8s  %8s  %8s  %8s  %8s\n', 'THETA','N_ss','K_ss','Y_ss','C_ss','i_ss');
fprintf('%s\n', repmat('-',1,56));
idx_print = round(linspace(1, n_th, 6));
for jj = idx_print
    fprintf('%8.4f  %8.6f  %8.6f  %8.6f  %8.6f  %8.6f\n', ...
        THETA_grid(jj), N_cia(jj), K_cia(jj), Y_cia(jj), ...
        C_cia(jj), I_cia(jj));
end
fprintf('\nMecanismo: (1+i) = THETA/beta sube con THETA.\n');
fprintf('Esto entra en la condicion de optimalidad laboral (MUY = -PHI*C - I),\n');
fprintf('distorsionando la decision trabajo-ocio y reduciendo N, K, Y, C en SS.\n');
