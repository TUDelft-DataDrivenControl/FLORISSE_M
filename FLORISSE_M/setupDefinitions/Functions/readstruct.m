function Struct = readstruct(FileName,Sheet)
% readstruct reads vertically structured excel worksheets in a struct with scalar fields,
% like Matlabs inbuilt 'readtable' reads horizontally structured worksheets in a table with column vector variables.
%
% The first column in the worksheet specifies the fieldnames, the second the according (scalar) values.
% Reading starts in the first row, an empty line in the first column indicates that additional information not to be read is following.

[~,~,Extension] = fileparts(FileName);
switch Extension
    
    case '.txt'
        
        % read text file
        fid = fopen(FileName,'r');
        Data = textscan(fid,'%s %s %*s','Delimiter','\t','MultipleDelimsAsOne',true,'CollectOutput',false); % ,'CommentStyle','%'
        fclose(fid);
        
        Data = horzcat(Data{:}); % concatenate contents of the cells into one cell array
        % Data = read_MultiDim(FileName,{'\t'},2); % works only if the same number of columns are present in every line
        
        % convert to right data type & format in matlab
        DataNum = str2double(Data); % convert character vectors denoting numbers to actual doubles
        Ind = not(isnan(DataNum));
        DataNum = num2cell(DataNum); % convert to cell array for assignment to Data
        Data(Ind) = DataNum(Ind);
    
    case {'.xlsx','.xls'}
        
        % read original excel contents in a cell array
        [~,~,Data] = xlsread(FileName,Sheet,'','basic'); % range 'A:B' could also be specified, but has long runtime and reads all empty rows as NaNs
        
    otherwise
        error('File must be either .txt or .xls/.xlsx!')
        
end

% use only the first two columns until an empty line appears in the first column (i.e. no fieldname given)
k=1;
while ischar(Data{k,1})
    LastRow=k;
    k=k+1;
    if k>size(Data,1)
        break
    end
end
Field = Data(1:LastRow,1);
Value = Data(1:LastRow,2);
if not(iscellstr(Field))
    error('First column of the worksheet must be character vectors denoting the fieldnames of the struct.')
end

% assign contents of the excel sheet to struct fields
for k=1:length(Field)
    if isnan(Value{k})
        Struct.(Field{k}) = []; % empty excel cells denote as NaN and are again assigned an empty value
    else
        Struct.(Field{k}) = Value{k};
    end
end


end