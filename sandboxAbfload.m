fileOne = 'C:\Users\Mondegreen\Documents\MATLAB\ephys\G1 7062017 BLA interneuron_0000.abf';
fileTwo = 'C:\Users\Mondegreen\Documents\MATLAB\ephys\G1 7112017  #1_0000.abf';
rampFile = 'C:\Users\Mondegreen\Documents\MATLAB\ephys\B01060617_0001.abf';
brendaFile = 'C:\Users\Mondegreen\Documents\MATLAB\ephys\B01060617_0000.abf';
% [d, si, h] = abfload( brendaFile );
analysis = AnalyzeHypDep( fileOne );
% d = squeeze( d(:,1,:) );
% plot( d )