%% Post-traitement Welch — simul3 (chaîne avec défauts)
%
%   acc_mesuree : signal de sortie de la chaîne (g, fs_dec = 500 Hz)
%   Défauts actifs :
%     1. Erreur d'échelle capteur : eps_capteur = +3 %
%     2. Bruit capteur dégradé   : 2 mg_rms
%     3. Plage CAN réduite       : ±5 g  (LSB doublé)

%% Estimation DSP par Welch sur acc_mesuree (fs_dec = 500 Hz)
N_fft_dec  = 1000;              % df = 0.5 Hz
overlap_dec = 500;              % recouvrement 50 %

[pxx, f_w] = pwelch(acc_mesuree, hann(N_fft_dec), overlap_dec, N_fft_dec, fs_dec);

% Profil cible interpolé sur les mêmes fréquences
log_S_ref = interp1(log10(dsp_in(:,1)), log10(dsp_in(:,2)), ...
                    log10(f_w(2:end)), 'linear', 'extrap');
S_ref = 10.^log_S_ref;

% Écart en dB fréquence par fréquence
ecart_dB = 10*log10(pxx(2:end) ./ S_ref);

%% g_rms mesuré (bande 4-200 Hz)
bande        = f_w >= 4 & f_w <= 200;
grms_mesure  = sqrt(trapz(f_w(bande), pxx(bande)));
grms_cible   = 0.4000;
ecart_rel    = 100 * (grms_mesure - grms_cible) / grms_cible;

fprintf('\n── Résultats simulation 3 (avec défauts) ────────────\n');
fprintf('fs entrée chaîne  : %g Hz\n',   fs);
fprintf('fs sortie chaîne  : %g Hz\n',   fs_dec);
fprintf('g_rms cible       : %.4f g\n',  grms_cible);
fprintf('g_rms mesuré      : %.4f g\n',  grms_mesure);
fprintf('Écart relatif     : %+.2f %%\n', ecart_rel);
fprintf('Défauts actifs    : eps_capteur=%+.0f%%  bruit=2 mg_rms\n', eps_capteur*100);
fprintf('────────────────────────────────────────────────────\n');

%% Affichage
fig = figure('Name', 'Post-traitement simul3 — chaîne avec défauts');

subplot('Position', [0.13 0.50 0.77 0.44]);
loglog(f_w(2:end), pxx(2:end), 'r-', 'LineWidth', 1.5); hold on;
loglog(dsp_in(:,1), dsp_in(:,2), 'b-o', 'LineWidth', 2);
grid on;
legend('DSP mesurée', 'DSP cible');
xlabel('Fréquence (Hz)'); ylabel('g²/Hz');
title('DSP');
xlim([1 200]);

subplot('Position', [0.13 0.16 0.77 0.24]);
semilogx(f_w(2:end), ecart_dB, 'k-', 'LineWidth', 1.5);
hold on; yline(0,'r--'); yline(3,'r:'); yline(-3,'r:');
grid on;
xlabel('Fréquence (Hz)'); ylabel('Écart (dB)');
title('Écart DSP mesurée');
xlim([1 200]);

% Bilan g_rms en bas de figure
txt = sprintf('g_{rms} cible : %.4f g     |     g_{rms} mesuré : %.4f g     |     Écart : %+.2f %%', ...
    grms_cible, grms_mesure, ecart_rel);
annotation(fig, 'textbox', [0 0 1 0.08], ...
    'String',              txt, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment',   'middle', ...
    'FontSize',            11, ...
    'FontWeight',          'bold', ...
    'EdgeColor',           'none', ...
    'BackgroundColor',     [0.94 0.94 0.94]);
