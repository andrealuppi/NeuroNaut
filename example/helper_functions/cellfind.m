function I = cellfind(myCellArray, stringToFind)
%Find index I of 
% I = cellfind(myCellArray, stringToFind)
% Returns I, the index of cells containing the desired string

if nargin < 2
    I = find(~cellfun('isempty', myCellArray));
else
    I = find(cellfun(@(x) isequal(x, stringToFind), myCellArray));
end

end