%% start4_train.m — Initialisation simulation d'entrainement
% InitFcn de simul4entrainement.slx
% Genere les 4 signaux (graine 42) et le signal de controle

clear; clc; close all;
params4;   % parametres communs (fs, DSP, capteur…)

%% Parametres specifiques entrainement
graine_train  = 42;
T_sig         = 300;        % s  duree signaux sources (> T_total_train)
T_mode_train  = 50;         % s  duree par mode
T_total_train = 4 * T_mode_train;   % 200 s
N_sig         = T_sig * fs;

%% Generation des 4 signaux sources (graine 42)
fprintf('=== Generation signaux entrainement (graine %d) ===\n', graine_train);
df  = 1 / T_sig;
k   = (1 : N_sig/2 - 1);
f_k = k * df;
rng(graine_train);

for cl = 1:4
    log_S    = interp1(log10(dsps{cl}(:,1)), log10(dsps{cl}(:,2)), ...
                       log10(f_k), 'linear', 'extrap');
    A        = sqrt(10.^log_S * df / 2);
    phi      = 2*pi * rand(1, length(f_k));
    ACC_pos  = A .* exp(1j*phi);
    ACC_full = [0, ACC_pos, 0, conj(fliplr(ACC_pos))];
    sig      = real(ifft(ACC_full))' * N_sig;
    t_sig    = (0:N_sig-1)' / fs;
    varname  = ['sig_' lower(MODES{cl}) '_ts'];
    assignin('base', varname, timeseries(sig, t_sig));
    fprintf('  %s : g_rms = %.4f g\n', MODES{cl}, sqrt(mean(sig.^2)));
end

%% Signal de controle (classe reelle)
ctrl_vals = [1; 2; 3; 4];
ctrl_t    = [0; T_mode_train; 2*T_mode_train; 3*T_mode_train];
ctrl_ts   = timeseries(ctrl_vals, ctrl_t);

%% Affichage DSP
couleurs = {[0.5 0.5 0.5],[0.85 0.33 0.10],[0.00 0.45 0.74],[0.47 0.67 0.19]};
figure('Name','DSP — 4 modes (entrainement)','NumberTitle','off');
for cl = 1:4
    loglog(dsps{cl}(:,1), dsps{cl}(:,2), '-o', 'Color', couleurs{cl}, ...
        'LineWidth',2,'MarkerFaceColor',couleurs{cl},'DisplayName',MODES{cl});
    hold on;
end
grid on; legend('Location','southwest');
xlabel('Frequence (Hz)'); ylabel('DSP (g^2/Hz)');
title('Profils DSP — ASTM D4169 Level II + ICM-20948'); xlim([1 300]);

fprintf('\nParametres entrainement :\n');
fprintf('  T_total = %d s  (%d modes x %d s)\n', T_total_train, 4, T_mode_train);
fprintf('  Sequence : Arret(0s) -> Camion(%ds) -> Train(%ds) -> Avion(%ds)\n', ...
        T_mode_train, 2*T_mode_train, 3*T_mode_train);
fprintf('\n=== start4_train.m termine — lancez create_entrainement.m ===\n');
