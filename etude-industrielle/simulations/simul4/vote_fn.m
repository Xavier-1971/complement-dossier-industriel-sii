function label = vote_fn(idx)
%VOTE_FN  Vote majoritaire sur les labels des k plus proches voisins
%  Entree : idx   vecteur 1x3 (indices dans y_train, retournes par knn_search_fn)
%  Sortie : label scalaire  1=Arret  2=Camion  3=Train  4=Avion
%#codegen
coder.extrinsic('vote_wrapper');

label = double(0);
label = vote_wrapper(idx);
end
