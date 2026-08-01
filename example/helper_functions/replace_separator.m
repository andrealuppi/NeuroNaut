function[replacement_string] = replace_separator(mystring, old_separator, new_separator)
% Replace occurrence of one separator with another, for exampl whitespace
% with underscore or vice versa

replacement_string = mystring;
if iscell(mystring)
    for i = 1:numel(mystring)
        replacement_string{i}(regexp(mystring{i},['[', old_separator, ']']))=[new_separator];
    end
else
    replacement_string(regexp(mystring,['[', old_separator, ']']))=[new_separator];
end