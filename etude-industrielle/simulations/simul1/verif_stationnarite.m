%% Vérification de la stationnarité du signal généré par init1.m
% Ce script trace l'évolution de la moyenne µ et de la variance σ²
% par fenêtres glissantes de 10 s sur les 600 s du signal.
% Prérequis : avoir exécuté init1.m (variables acc, t, fs disponibles)

%% Paramètres de la fenêtre
T_fen = 10;               % durée de la fenêtre (s)
N_fen = T_fen * fs;       % nombre d'échantillons par fenêtre

N_total = length(acc);
N_fenetres = floor(N_total / N_fen);  % fenêtres non chevauchantes

%% Calcul de µ et σ² par fenêtre
mu    = zeros(1, N_fenetres);
sigma2 = zeros(1, N_fenetres);
t_centre = zeros(1, N_fenetres);

for i = 1:N_fenetres
    idx = (i-1)*N_fen + 1 : i*N_fen;
    fenetre = acc(idx);
    mu(i)     = mean(fenetre);
    sigma2(i) = var(fenetre);
    t_centre(i) = t(idx(1) + N_fen/2);  % instant central de la fenêtre
end

%% Valeurs théoriques
mu_th     = 0;
sigma2_th = grms_ref^2;   % σ² = g_rms² (calculé dans init1.m)

%% Affichage
figure('Name', 'Vérification stationnarité', 'NumberTitle', 'off', ...
       'Position', [100 100 900 500]);

% --- Moyenne ---
subplot(2,1,1);
plot(t_centre, mu, 'b-o', 'MarkerSize', 4, 'LineWidth', 1.2);
yline(mu_th, 'r--', '\mu_{th} = 0', 'LabelHorizontalAlignment', 'left', ...
      'LineWidth', 1.5);
xlabel('Temps (s)');
ylabel('\mu (g)');
title(sprintf('Moyenne par fenêtre de %d s', T_fen));
grid on;
ylim([-0.05 0.05]);

% --- Variance ---
subplot(2,1,2);
plot(t_centre, sigma2, 'b-o', 'MarkerSize', 4, 'LineWidth', 1.2);
yline(sigma2_th, 'r--', sprintf('\\sigma^2_{th} = %.4f g^2', sigma2_th), ...
      'LabelHorizontalAlignment', 'left', 'LineWidth', 1.5);
xlabel('Temps (s)');
ylabel('\sigma^2 (g^2)');
title(sprintf('Variance par fenêtre de %d s', T_fen));
grid on;

sgtitle('Stationnarité du signal synthétique — init1.m', 'FontWeight', 'bold');

%% Bilan chiffré
fprintf('--- Bilan stationnarité ---\n');
fprintf('µ     : moyenne = %.2e g,  écart-type = %.2e g  (théorique : 0)\n', ...
        mean(mu), std(mu));
fprintf('σ²    : moyenne = %.4f g², écart-type = %.4f g²  (théorique : %.4f g²)\n', ...
        mean(sigma2), std(sigma2), sigma2_th);
fprintf('CV(σ²) = %.1f %%  (< 5 %% → stationnarité confirmée)\n', ...
        100 * std(sigma2) / mean(sigma2));
