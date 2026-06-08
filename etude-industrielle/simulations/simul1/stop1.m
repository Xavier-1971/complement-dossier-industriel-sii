%% Post-traitement Welch
t_out = (0 : length(acc_mesuree)-1)' / fs;

% Estimation DSP par Welch
N_fft = 10000;   % df = 0.5 Hz → bins à 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0 Hz
overlap = 5000;  % 50 %
[pxx, f_w] = pwelch(acc_mesuree, hann(N_fft), overlap, N_fft, fs);

% Profil cible interpolé sur les mêmes fréquences
log_S_ref = interp1(log10(dsp_in(:,1)), log10(dsp_in(:,2)), log10(f_w(2:end)), 'linear', 'extrap');
S_ref = 10.^log_S_ref;

% Écart en dB fréquence par fréquence
ecart_dB = 10*log10(pxx(2:end) ./ S_ref);

% g_rms mesuré vs analytique (bande identique à la normalisation init.m)
bande = f_w >= 4 & f_w <= 200;         % cohérent avec la normalisation 4-200 Hz
grms_mesure  = sqrt(trapz(f_w(bande), pxx(bande)));
grms_cible   = 0.4000;
ecart_rel    = 100 * (grms_mesure - grms_cible) / grms_cible;

fprintf('g_rms cible   : %.4f g\n', grms_cible);
fprintf('g_rms mesuré  : %.4f g\n', grms_mesure);
fprintf('Écart relatif : %+.2f %%\n', ecart_rel);

% Affichage
fig = figure('Name','Post-traitement');

% Layout (coordonnées normalisées [gauche bas largeur hauteur]) :
%   annotation  : bande basse  y = 0.00 → 0.08
%   subplot 2   : écart dB     y = 0.16 → 0.40
%   subplot 1   : DSP          y = 0.50 → 0.94

subplot('Position', [0.13 0.50 0.77 0.44]);
loglog(f_w(2:end), pxx(2:end), 'r-', 'LineWidth', 1.5); hold on;
loglog(dsp_in(:,1), dsp_in(:,2), 'b-o', 'LineWidth', 2);
grid on;
legend('DSP mesurée', 'DSP cible');
xlabel('Fréquence (Hz)'); ylabel('g²/Hz');
xlim([1 200]);

subplot('Position', [0.13 0.16 0.77 0.24]);
semilogx(f_w(2:end), ecart_dB, 'k-', 'LineWidth', 1.5);
hold on; yline(0,'r--'); yline(3,'r:'); yline(-3,'r:');
grid on;
xlabel('Fréquence (Hz)'); ylabel('Écart (dB)');
title('Écart DSP mesurée / cible');
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
