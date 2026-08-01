function[] = plot_NullHistogram(emp, nulls, p_perm, optional_title)
% Given an empirical value, nulls, and precomputed p-value, plots the distribution

full_range = max(max([nulls(:); emp])) - min(min([nulls(:); emp]));
null_range = max(max([nulls(:)])) - min(min([nulls(:)]));

if null_range > (0.2 .* full_range)
    numBins = 40;
elseif null_range > (0.1 .* full_range)
    numBins = 10;
else
    numBins = 5;
end

%Plot histogram with cutoffs
colr = [0.75 0.75 0.75];
figure;
hold on
h = histogram(nulls, numBins, 'Normalization', 'probability', 'edgecolor', 'w', ...
    'facecolor', colr, 'facealpha', 1, 'linewidth', 0.8);
l = line([emp emp], get(gca, 'ylim'), 'linestyle', '--', ...
    'color', 'r', 'linewidth', 2.5);

xlabel(['observed value'])
ylabel('frequency of occurrence')
legend(l,['{\it r}=' num2str(round(emp, 2)) newline ...
    '{\it p}=' num2str(round(p_perm, 3))])
legend boxoff

if exist('optional_title', 'var')
    title(replace_separator(optional_title, '_', ' '));
end

end