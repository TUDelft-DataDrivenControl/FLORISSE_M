function Out = append_StructFields(varargin)
% append_StructFields appends the fields of Struct2 to Struct1 if Struct2 is nonempty
% If a field with different content already exists in Struct1, a new field is created with a '_1' appended to the field name.
% Both structs must be scalar, but can have arbitrary field contents.

if length(varargin)<=1
    
    error('Not enough input arguments!')
    
elseif length(varargin)==2
    
    Struct1 = varargin{1};
    Struct2 = varargin{2};
    
    % extract names of fields
    FieldNames1 = fieldnames(Struct1);
    FieldNames2 = []; % initialize with empty scalar in case Struct2 is empty (fieldnames doesn't work on empty structs)
    if not(isempty(Struct2))
        FieldNames2 = fieldnames(Struct2);
    end
    
    % copy each field of Struct2 to Struct1
    for k=1:length(FieldNames2) % does not enter if FieldNames2 is empty (length(FieldNames2)==0)
        Name = FieldNames2{k};
        if any(strcmp(Name,FieldNames1)) && not(isequal(Struct1.(Name),Struct2.(Name)))
            Struct1.([Name,'_1']) = Struct2.(Name); % do not overwrite equally named fields with different contents
        else
            Struct1.(Name) = Struct2.(Name);
        end
    end
    
    Out = Struct1;

else % repeatedly combine the first two elements
    
    Result = append_StructFields(varargin{1:2}); % stable case, does not call itself
    Out = varargin(2:end);
    Out{1} = Result;
    
    % call function again until case 2 is met and it doesnt call itself again (recursive function)
    Out = append_StructFields(Out{:}); % Out is finally written when function does not call itself anymore

end


end