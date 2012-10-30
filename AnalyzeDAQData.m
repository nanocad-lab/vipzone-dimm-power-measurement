% ********************************************
% ************ AnalyzeDAQData ***************
% ***** Version 1.9, September 6, 2012 *******
% ********************************************
% 
% ** AUTHOR
%
% Mark Gottscho
% UCLA NanoCAD Lab
% mgottscho@ucla.edu
% 
% ** USAGE
% 
% To execute the function, simply call 'AnalyzeDimmData' with the
% following arguments:
% 
% data                  The raw voltage data matrix for a test.
%                       Column 1: Time in seconds
%                       Column 2: Channel 1
%                       ...
%                       Column n: Channel n-1
%
% graphTitle            STRING: describe the device and test for the graph title, i.e.
%                       'DIMM J Memtest86 3.5b MWG MOD - Seq. Write 1,
%                       Cache On, at 30C'
%
% plotFile              STRING: Filename prefix for the EPS plot.
%
% winSize               Number of samples to average for plot purposes.
%
% resistorValue         Value of the resistor across which the voltage data
%                       was collected, in Ohms. This is used to convert the
%                       voltage data to Watts.
%
% supplyVoltage         The supply voltage for the DIMMs. This is used to
%                       convert the voltage data to Watts.
% 
% ** OUTPUT
% 
% The function will display plots of the power consumption profile for
% the test, output the mean power as well as sample variance, and write relevant data
% to a timestamped file.
%
% ** RETURN
% Returns the mean power as well as the sample
% variance for the test.

function [meanPower, variance] = AnalyzeDAQData(data, graphTitle, plotFile, winSize, resistorValue, supplyVoltage)

display('****************** UCLA NanoCAD Lab, Electrical Engineering *********************');
display('************* AnalyzeDAQData Version 1.9, September 6, 2012 *********************');
display(' ');
display('For help, try ''help AnalyzeDimmData''.');
display(' ');

% Get the matrix size
dataSize = size(data);
m = dataSize(1); % number of rows is the number of data points (for each channel)
n = dataSize(2); % number of columns - 1 is the number of channels
nChannels = n - 1;

if (nChannels < 0 || nChannels > 8)
    display('Bad number of channels');
    return
end

% Convert the voltage readings to Watts using the resistor value and supply
% voltage (DIMM PWR = MeasuredV/Resistor * SupplyV)
for chan = 1 : nChannels
    data(:,chan+1) = data(:,chan+1) / resistorValue * supplyVoltage;
end
   

% Calculate the average samples in new matrices
avg_data = NaN(ceil(m/winSize), nChannels+2); % Allocate the matrix -- 2 extra columns for timestamps and total power
avg_data_size = size(avg_data);

% Fetch the corresponding time values
for i = 1 : (avg_data_size(1)-2)
    avg_data(i,1) = data(i*winSize, 1);
end

% Compute sample averages
for chan = 1 : nChannels % For each channel of data
    for i = 1 : (avg_data_size(1)-2) % For each slot in the average data matrix
        avg_data(i,chan+1) = mean(data(i*winSize+1:1:i*winSize+winSize, chan+1)); % Compute the average power over 64 samples
    end
end

% Compute total power
for i = 1 : (avg_data_size(1)-2)
   avg_data(i, nChannels+2) = sum(avg_data(i, 2:nChannels+1)); 
end

%avg_data = avg_data(~isnan(avg_data)); % Remove any NaN from the matrix,
%if they exist.

% Plot
myColors = {'b-', 'r-', 'm-', 'k-', 'b--', 'r--', 'm--', 'k--'};
totalColor = 'g-';
labels = {'Total', 'DIMM1 (Chan A.1)', 'DIMM2 (Chan B.1)', 'DIMM3 (Chan C.1)', 'DIMM4 (Chan D.1)', 'DIMM5 (Chan A.2)', 'DIMM6 (Chan B.2)', 'DIMM7 (Chan C.2)', 'DIMM8 (Chan D.2)'};

if nChannels == 1 % Stack averaged data on raw data
    plot(data(:,1), data(:,2), myColors{1}, avg_data(:,1), avg_data(:,2), myColors{2});
    legend({'Raw data', 'Averaged data'});
else % Stack averaged data, don't plot raw data
    hold on;
    
    plot(avg_data(:,1), avg_data(:, nChannels+2), totalColor); % Plot total power against timestamps
    
    for chan = 1 : nChannels
        plot(avg_data(:,1), avg_data(:,chan+1), myColors{chan}); % Plot each channel against the same timestamps
    end
    
    legend(labels(1:nChannels+1));
    hold off;
end

set(gca,'FontSize',12);
title(graphTitle);
xlabel('Time (s)');
ylabel('Power (W)');

% Calculate & return the mean power value.
meanPower = NaN(nChannels,1);
variance = NaN(nChannels,1);

for chan = 1 : nChannels
   meanPower(chan) = mean(data(:,chan+1));
   variance(chan) = var(data(:,chan+1));
end

input('Press Enter when you are ready to save the figure...', 's');
display 'Writing plot file...'

% Output figure to EPS file.
print(1, '-depsc', plotFile);

end






