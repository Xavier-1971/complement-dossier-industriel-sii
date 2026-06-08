function idx = knn_search_fn(feat_norm)
%KNN_SEARCH_FN  Recherche des k=3 plus proches voisins dans X_train normalise
%  Entree : feat_norm  vecteur 1x6 (normalise par normalisation_fn)
%  Sortie : idx        vecteur 1x3 (indices dans X_train, base 1)
%#codegen
coder.extrinsic('knn_search_wrapper');

idx = zeros(1, 3);
idx = knn_search_wrapper(feat_norm);
end
