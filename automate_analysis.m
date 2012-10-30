DIMM_letter = input('DIMM Letter: ', 's');
temp = input('Temp (C): ', 's');
wdata = load(['raw/DIMM_' DIMM_letter '_write_' temp 'C_10k.dat']);
rdata = load(['raw/DIMM_' DIMM_letter '_read_' temp 'C_10k.dat']);
idata = load(['raw/DIMM_' DIMM_letter '_idle_' temp 'C_10k.dat']);

[wavg,var] = AnalyzeDimmData(wdata, 1, ['DIMM ' DIMM_letter ' Write Address Only at ' temp 'C'], ['processed/DIMM_' DIMM_letter '_write_' temp 'C_10k'], 32, 0.02, 1.500);
[ravg,var] = AnalyzeDimmData(rdata, 1, ['DIMM ' DIMM_letter ' Read Address Only at ' temp 'C'], ['processed/DIMM_' DIMM_letter '_read_' temp 'C_10k'], 32, 0.02, 1.500);
[iavg,var] = AnalyzeDimmData(idata, 1, ['DIMM ' DIMM_letter ' Idle at ' temp 'C'], ['processed/DIMM_' DIMM_letter '_idle_' temp 'C_10k'], 32, 0.02, 1.500);

wavg
ravg
iavg
