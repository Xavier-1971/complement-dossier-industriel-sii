%% start4_infer.m — Initialisation simulation d'inference
% InitFcn de simul4inference.slx
% Genere les 4 signaux (graine 100) — suppose que mdl_knn est dans le workspace

%% Verification du modele k-NN
if ~exist('mdl_knn', 'var')
    error(['mdl_knn introuvable dans le workspace.\n' ...
           'Lancez simul4entrainement.slx d''abord pour entrainer le classifieur.']);
end
fprintf('=== mdl_knn detecte dans le workspace ===\n');

%% Parametres communs (sans clear — preserve mdl_knn)
params4;

%% Parametres specifiques inference
graine_infer  = 100;        % graine differente de l'entrainement (42)
T_sig         = 300;        % s  duree signaux sources
T_mode_infer  = 60;         % s  duree par mode
T_total_infer = 4 * T_mode_infer;   % 240 s
N_sig         = T_sig * fs;

%% Generation des 4 signaux sources (graine 100)
fprintf('=== Generation signaux inference (graine %d) ===\n', graine_infer);
df  = 1 / T_sig;
k   = (1 : N_sig/2 - 1);
f_k = k * df;
rng(graine_infer);

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

%% Signal de controle (classe reelle pour comparaison scope)
ctrl_vals = [1; 2; 3; 4];
ctrl_t    = [0; T_mode_infer; 2*T_mode_infer; 3*T_mode_infer];
ctrl_ts   = timeseries(ctrl_vals, ctrl_t);

fprintf('\nParametres inference :\n');
fprintf('  Graine : %d  (differente de l''entrainement : 42)\n', graine_infer);
fprintf('  T_total = %d s  (%d modes x %d s)\n', T_total_infer, 4, T_mode_infer);
fprintf('  Sequence : Arret(0s) -> Camion(%ds) -> Train(%ds) -> Avion(%ds)\n', ...
        T_mode_infer, 2*T_mode_infer, 3*T_mode_infer);
fprintf('\n=== start4_infer.m termine — la simulation peut demarrer ===\n');
