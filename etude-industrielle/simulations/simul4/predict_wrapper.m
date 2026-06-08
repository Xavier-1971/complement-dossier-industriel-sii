function label = predict_wrapper(feat)
%PREDICT_WRAPPER  k-NN prediction depuis le workspace (appelee en extrinsic)
%  k-NN retourne un double directement (contrairement a TreeBagger)
mdl_knn = evalin('base', 'mdl_knn');
label   = double(predict(mdl_knn, feat));
end
