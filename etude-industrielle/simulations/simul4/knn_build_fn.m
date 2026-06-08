function X_norm = knn_build_fn()
%KNN_BUILD_FN  Construit la matrice X_train normalisee (z-score)
%  Appelee une seule fois depuis knn_search_fn (variable persistante).
%  Lit X_train, mu_train, sigma_train depuis le workspace.
X_tr    = evalin('base', 'X_train');
mu_loc  = evalin('base', 'mu_train');
sig_loc = evalin('base', 'sigma_train');
X_norm  = (X_tr - mu_loc) ./ sig_loc;
end
