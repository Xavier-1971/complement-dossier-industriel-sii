%% start4_infer_knn.m — Initialisation simulation inference explicite (KNN Search)
% InitFcn de simul4knn_explicite.slx
% Suppose que mdl_knn, X_train et y_train sont dans le workspace
% (produits par simul4entrainement.slx + stop4_train.m)

%% Verification des prerequis
if ~exist('mdl_knn','var') || ~exist('X_train','var') || ~exist('y_train','var')
    error(['mdl_knn / X_train / y_train introuvables.\n' ...
           'Lancez simul4entrainement.slx d''abord.']);
end
fprintf('=== Prerequis detectes dans le workspace ===\n');

%% Parametres communs (sans clear — preserve le workspace)
params4;

%% Extraction des parametres de normalisation depuis mdl_knn
% mdl_knn a ete entraine avec Standardize=true → Mu et Sigma disponibles
mu_train    = mdl_knn.Mu;
sigma_train = mdl_knn.Sigma;

%% Creation de l'objet searcher (sur donnees normalisees)
X_norm       = (X_train - mu_train) ./ sigma_train;
knn_searcher = createns(X_norm, 'NSMethod', 'exhaustive', 'Distance', 'euclidean');

fprintf('  knn_searcher : %d points x %d features (distance euclidienne)\n', ...
        size(X_norm, 1), size(X_norm, 2));
fprintf('  mu_train et sigma_train disponibles\n');

%% Signaux sources (graine 100 — identique a simul4inference.slx)
graine_infer  = 100;
T_sig         = 300;
T_mode_infer  = 60;
T_total_infer = 4 * T_mode_infer;
N_sig         = T_sig * fs;

fprintf('=== Generation signaux (graine %d) ===\n', graine_infer);
df  = 1/T_sig;
k   = (1 : N_sig/2-1);
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

ctrl_vals = [1; 2; 3; 4];
ctrl_t    = [0; T_mode_infer; 2*T_mode_infer; 3*T_mode_infer];
ctrl_ts   = timeseries(ctrl_vals, ctrl_t);

fprintf('\n=== start4_infer_knn.m termine ===\n');
