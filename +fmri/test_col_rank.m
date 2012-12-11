function A = test_col_rank(M)
% TEST_COL_RANK
% Tests whether a design matrix is rank deficient and, if it is, it tell
% you which column should be removed in order to avoid rank deficiency. 
%
% A = test_col_rank(M);
%
% where M is either an RxK double array with K explanatory variables or a
% string containing a .csv file name, from which the design matrix should
% be read.
%
% A is an KxK matrix containing the linear mapping coefficients that can be
% used to build the redundant columns using the other columns. E.g. if
% column i is redundant then:
%
% M(:,i) = M(:, setdiff(1:K, i))*A(:,i)
%
%
%
% German Gomez-Herrero
% g.gomez@nin.knaw.nl

MIN_COEFF = 0.001;

if ischar(M),
    M = dlmread(M);
end

A = zeros(size(M,2),size(M,2));
if rank(M) < size(M,2),
    for i = 1:size(M,2)
       otherIdx = setdiff(1:size(M,2), i);
       A(otherIdx,i) = pinv(M(:,otherIdx))*M(:,i);     
    end
else
    fprintf('\nMatrix is of full column rank');    
end

numCoeffs = sum(abs(A)> MIN_COEFF);
numCoeffs = fliplr(numCoeffs);
[numCoeffs, idx] = min(numCoeffs);
idx = size(A,2)-idx+1;

fprintf('\nRemove column %s. See:', num2str(idx));
fprintf('\n\n');

nonZero = abs(A(:,idx)) > MIN_COEFF;
nonZeroIdx = find(nonZero);
str = ['C' num2str(idx) ' = ' num2str(A(nonZeroIdx(1),idx)) '*C' num2str(nonZeroIdx(1))];
for i = 2:numCoeffs
    if A(nonZeroIdx(i),idx) > 0,
        str = [str ' + ' num2str(A(nonZeroIdx(i),idx)) '*C' num2str(nonZeroIdx(i))]; %#ok<AGROW>
    else
        str = [str ' - ' num2str(abs(A(nonZeroIdx(i),idx))) '*C' num2str(nonZeroIdx(i))]; %#ok<AGROW>
    end
end
fprintf(str);
fprintf('\n');

end