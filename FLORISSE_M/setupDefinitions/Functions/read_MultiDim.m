function Data = read_MultiDim(TextFile,Delim,NDims,NumOption)
%
% INPUT:
% TextFile: character vector specifying the path to a text file containing the multi-dimensional numeric data
% DimDelim: cell array of character vectors specifying the dimension delimiter for the second dimension and third upwards
%           1st Dimension: always newline '\r\n'
%           2nd Dimension: usually tab '\t' or space ' '
%           3rd,...,Nth dimension: e.g. semicolon ';' that is repeated for every additional dimension
% NDims: numeric scalar specifying the number of dimensions contained in the TextFile
% NumOption: logical scalar triggering conversion from cell to numeric array
%
% OUTPUT:
% Data: NDims-dimensional (cell) array containing the data in the text file

DimDelims = cell(1,NDims); % delimiters of the dimensions in the order how the array will be split
DimDelims(1) = Delim(1);
DimDelims{2} = '\r\n';
for k=1:NDims-2 % define delimiters for dimensions 3...N
    DimDelims{2+k} = ['\r\n',repmat(Delim{2},[1 k]),'\r\n'];
end
DimDelims = compose(DimDelims); % convert escape characters to literal characters (e.g. '\n' to a literal newline)
DimOrder = 1:NDims;
DimOrder([1 2]) = [2 1]; % as newlines are first dimension delimiter

% read data in the text file as a character array and replace multiple second dimension delimiters with one
Data = fileread(TextFile);
MultDelim = repmat(Delim{1},[1 2]);
while contains(Data,MultDelim)
    Data = replace(Data,MultDelim,Delim{1});
end

% repeatedly split the dimensions from highest to lowest (and later arrange the result from lowest to highest dimension)
for k=NDims:-1:1
    Data = split(Data,DimDelims{k},DimOrder(k)); % take care, singleton dimensions are introduced (but the dimensions stay in the right order)
end

Data = squeeze(Data); % remove singleton dimensions from array that was split in the right order
if nargin==4 && NumOption==true
    Data = str2double(Data); % convert cell array to numeric array
end

% alternatively:
% [~,DimSort] = sort(fliplr(DimOrder)); % as dimensions are split from lowest to highest
% Data = permute(Data,DimSort); % use permute and split in wrong order before
    
% --------------------------
% alternatively: Low-level parsing
% fopen
% fgetl
% if
% fclose

end