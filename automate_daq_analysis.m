filePrefix = input('File prefix: ', 's');
data = load([filePrefix '.csv']);
graphTitle = input('Graph Title: ', 's');

[avg,var] = AnalyzeDAQData(data, graphTitle, filePrefix, 32, 0.02, 1.500);

avg
var