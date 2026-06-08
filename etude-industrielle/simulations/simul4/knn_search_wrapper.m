function idx = knn_search_wrapper(feat_norm)
%KNN_SEARCH_WRAPPER  Recherche k-NN appelee comme fonction extrinsèque
%  Construit X_train normalise et retourne les 3 indices les plus proches.
X_tr    = evalin('base', 'X_train');
mu_loc  = evalin('base', 'mu_train');
sig_loc = evalin('base', 'sigma_train');
X_norm  = (X_tr - mu_loc) ./ sig_loc;
idx     = knnsearch(X_norm, feat_norm, 'K', 3);
end
