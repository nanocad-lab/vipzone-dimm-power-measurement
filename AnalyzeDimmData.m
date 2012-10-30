% ********************************************
% ************ AnalyzeDimmData ***************
% ****** Version 1.8.1, August 24, 2012 ******
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
% data                  The raw voltage data matrix for a test. For each channel, Column 1:
%                       time in seconds. Column 2: voltages.
%
% nChannels             The number of data channels. Each channel has time
%                       and values.
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

function [meanPower, variance] = AnalyzeDimmData(data, nChannels, graphTitle, plotFile, winSize, resistorValue, supplyVoltage)

display('****************** UCLA NanoCAD Lab, Electrical Engineering **********************');
display('*************** AnalyzeDimmData Version 1.8, March 7, 2012 ***********************');
display(' ');
display('For help, try ''help AnalyzeDimmData''.');
display(' ');

% Convert the voltage readings to Watts using the resistor value and supply
% voltage (DIMM PWR = MeasuredV/Resistor * SupplyV)
for chan = 1 : nChannels
    data(:,chan*2) = data(:,chan*2) / resistorValue * supplyVoltage;
end
   
% Get the matrix size
dataSize = size(data);
n = dataSize(1); % number of rows is the number of data points (for each channel)

% Calculate the average samples in new matrices
avg_data = NaN(ceil(n/winSize), nChannels*2);
avg_data_size = size(avg_data);

% Compute sample averages
for chan = 1 : nChannels % For each channel of data
    for i = 1 : (avg_data_size(1)-2) % For each slot in the average data matrix
        avg_data(i,chan*2-1) = data(i*winSize, chan*2-1); % Fetch the corresponding time values for each average data point
        avg_data(i,chan*2) = mean(data(i*winSize+1:1:i*winSize+winSize, chan*2)); % Compute the average power over 64 samples
    end
end

%avg_data = avg_data(~isnan(avg_data)); % Remove any NaN from the matrix,
%if they exist.

% Plot
myColors = {'c-', 'b-', 'r-', 'm-'};
labels = {'DIMM1Avg', 'DIMM2Avg', 'DIMM3Avg', 'DIMM4Avg'};

if nChannels == 1 % Stack averaged data on raw data
    plot(data(:,1), data(:,2), myColors{1}, avg_data(:,1), avg_data(:,2), myColors{2});
    legend({'Raw data', 'Averaged data'});
else % Stack averaged data, don't plot raw data
    hold on;
    for chan = 1 : nChannels
        plot(avg_data(:,chan*2-1), avg_data(:,chan*2), myColors{chan});
    end
    legend(labels(1:nChannels));
    hold off;
end

set(gca,'FontSize',12);
title(graphTitle);
xlabel('Time (s)');
ylabel('Power (W)');

% Calculate & return the mean power value.
meanPower = NaN(nChannels);
variance = NaN(nChannels);

for chan = 1 : nChannels
   meanPower(chan) = mean(data(:,chan*2));
   variance(chan) = var(data(:,chan*2));
end

input('Press Enter when you are ready to save the figure...', 's');
display 'Writing plot file...'

% Output figure to EPS file.
print(1, '-depsc', plotFile);

end






