%% start4.m — Initialisation simulation classification mode de transport
% 4 classes : 1=Arret  2=Camion  3=Train  4=Avion
% Chaque signal est genere independamment (300s), Simulink commute toutes les 60s

clear; clc; close all;

%% =========================================================
%  PARAMETRES
%% =========================================================
fs      = 250;      % Hz  (Nyquist 125 Hz > DLPF 111 Hz)
T_sig   = 300;      % s   duree de chaque signal source
T_mode  = 60;       % s   duree de chaque mode dans la sequence Simulink
T_total = 4 * T_mode;  % = 240 s
N_sig   = T_sig * fs;
T_win   = 10;       % s   fenetre d'analyse
N_win   = T_win * fs;  % = 2500 echantillons
graine  = 42;

MODES   = {'Arret','Camion','Train','Avion'};

%% =========================================================
%  1. PROFILS DSP [f(Hz), S(g2/Hz)]
%  Source : ASTM D4169-16 Table X1.1, Assurance Level II
%           Arret : datasheet ICM-20948 (120 ug/rtHz)
%% =========================================================
noise_density = 120e-6;
S_plancher    = noise_density^2;

dsp_arret  = [1,   S_plancher; 200, S_plancher];
dsp_camion = [  1, 0.00005;  4, 0.01; 16, 0.01; 40, 0.001; 300, 0.00001];
dsp_train  = [  1, 0.00001;  2, 0.001; 80, 0.001; 90, 0.0004; 200, 0.00001];
dsp_avion  = [  2, 0.0002; 12, 0.01; 100, 0.01; 200, 0.00001];
dsps = {dsp_arret, dsp_camion, dsp_train, dsp_avion};

%% =========================================================
%  2. AFFICHAGE DSP
%% =========================================================
couleurs = {[0.5 0.5 0.5],[0.85 0.33 0.10],[0.00 0.45 0.74],[0.47 0.67 0.19]};
figure('Name','DSP — 4 modes','NumberTitle','off');
for cl = 1:4
    loglog(dsps{cl}(:,1), dsps{cl}(:,2), '-o', 'Color', couleurs{cl}, ...
        'LineWidth',2,'MarkerFaceColor',couleurs{cl},'DisplayName',MODES{cl});
    hold on;
end
grid on; legend('Location','southwest');
xlabel('Frequence (Hz)'); ylabel('DSP (g2/Hz)');
title('Profils DSP — ASTM D4169 Level II + ICM-20948'); xlim([1 300]);

%% =========================================================
%  3. GENERATION DES 4 SIGNAUX SOURCES (T_sig = 300 s chacun)
%% =========================================================
fprintf('=== Generation des signaux sources ===\n');
df  = 1/T_sig;
k   = (1 : N_sig/2-1);
f_k = k * df;
rng(graine);

for cl = 1:4
    log_S    = interp1(log10(dsps{cl}(:,1)), log10(dsps{cl}(:,2)), ...
                       log10(f_k), 'linear','extrap');
    A        = sqrt(10.^log_S * df / 2);
    phi      = 2*pi*rand(1, length(f_k));
    ACC_pos  = A .* exp(1j*phi);
    ACC_full = [0, ACC_pos, 0, conj(fliplr(ACC_pos))];
    sig      = real(ifft(ACC_full))' * N_sig;
    t_sig    = (0:N_sig-1)' / fs;
    varname  = ['sig_' lower(MODES{cl}) '_ts'];
    assignin('base', varname, timeseries(sig, t_sig));
    fprintf('  %s : g_rms = %.4f g\n', MODES{cl}, sqrt(mean(sig.^2)));
end

%% =========================================================
%  4. SIGNAL DE CONTROLE DU MULTIPORT SWITCH
%     ctrl = 1 → Arret, 2 → Camion, 3 → Train, 4 → Avion
%% =========================================================
ctrl_vals = [1; 2; 3; 4];
ctrl_t    = [0; T_mode; 2*T_mode; 3*T_mode];
ctrl_ts   = timeseries(ctrl_vals, ctrl_t);   % commute toutes les T_mode secondes

%% =========================================================
%  5. PARAMETRES CAPTEUR ICM-20948
%% =========================================================
fc_dlpf   = 111;
[b_dlpf, a_dlpf] = butter(2, fc_dlpf/(fs/2), 'low');
sigma_bruit = noise_density * sqrt(fs/2);
biais_acc   = 0.003;

fprintf('\n-- Capteur ICM-20948 --\n');
fprintf('  DLPF  : %d Hz\n', fc_dlpf);
fprintf('  Bruit : %.5f g RMS\n', sigma_bruit);
fprintf('  Biais : %.3f g\n', biais_acc);

%% =========================================================
%  6. GENERATION DONNEES D'ENTRAINEMENT
%% =========================================================
fprintf('\n=== Entrainement k-NN ===\n');

T_train  = 200; N_train = T_train*fs; df_t = 1/T_train;
k_t      = (1:N_train/2-1); f_t = k_t*df_t;
rng(graine+10);
X_train  = []; y_train = [];

% Application du modele capteur aux signaux d'entrainement
% (coherence avec la chaine Simulink : DLPF + bruit + biais)
bruit_power = sigma_bruit^2 * (1/fs);

for cl = 1:4
    log_S    = interp1(log10(dsps{cl}(:,1)), log10(dsps{cl}(:,2)), ...
                       log10(f_t), 'linear','extrap');
    A        = sqrt(10.^log_S * df_t / 2);
    phi      = 2*pi*rand(1, length(f_t));
    ACC_full = [0, A.*exp(1j*phi), 0, conj(fliplr(A.*exp(1j*phi)))];
    sig_tr   = real(ifft(ACC_full))' * N_train;

    % Modele capteur : DLPF + bruit blanc + biais
    sig_tr = filter(b_dlpf, a_dlpf, sig_tr);
    sig_tr = sig_tr + sqrt(bruit_power * fs) * randn(N_train, 1);
    sig_tr = sig_tr + biais_acc;

    n_fen    = floor(N_train/N_win);
    for w = 1:n_fen
        x_w  = sig_tr((w-1)*N_win+1 : w*N_win);
        feat = calc_features(x_w, fs, N_win);
        X_train = [X_train; feat]; %#ok<AGROW>
        y_train = [y_train; cl];   %#ok<AGROW>
    end
end

mdl_knn = fitcknn(X_train, y_train, ...
    'NumNeighbors', 3, ...
    'Standardize',  true);

cv  = crossval(mdl_knn, 'KFold', 5);
err = kfoldLoss(cv);
fprintf('  Erreur validation croisee 5-fold : %.1f %%\n', err*100);
fprintf('  %d fenetres x 6 features\n', size(X_train,1));

fprintf('\n=== start4.m termine — lancez create_model4.m ===\n');

%% =========================================================
%  FONCTIONS LOCALES
%% =========================================================
function feat = calc_features(x, fs_loc, N_loc)
    rms_val  = sqrt(mean(x.^2));
    crete    = max(abs(x)) / (rms_val + 1e-12);
    X_fft    = abs(fft(x)).^2 / (N_loc * fs_loc);
    X_one    = X_fft(1:N_loc/2+1);
    X_one(2:end-1) = 2*X_one(2:end-1);
    f_v      = (0:N_loc/2)' * fs_loc / N_loc;
    df_loc   = fs_loc / N_loc;
    E_tot    = sum(X_one)*df_loc + 1e-12;
    f_c      = sum(f_v.*X_one)*df_loc / E_tot;
    E_basse  = sum(X_one(f_v>=1  & f_v< 5))*df_loc/E_tot;
    E_milieu = sum(X_one(f_v>=5  & f_v<50))*df_loc/E_tot;
    E_haute  = sum(X_one(f_v>=50 & f_v<125))*df_loc/E_tot;
    feat = [rms_val, crete, f_c, E_basse, E_milieu, E_haute];
end
