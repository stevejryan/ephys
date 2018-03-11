function f = PlotHypDepSummaryFigure( analysis )
  f = figure;
  f.Position = [ 700, 300, 960, 540 ];
  a = gca;
  dt = 1 / analysis.samplesPerMs; % dt in milliseconds
  totalDuration = size( analysis.rawTraces, 1 );
  time = dt:dt:(totalDuration / analysis.samplesPerMs - 0);
  % plot traces
  dataLine = plot( time, analysis.rawTraces, 'b-' );
  hold( a, 'on' )
  depSpikes = analysis.dep.depSpikes;
  % plot spike init
  for i=1:numel( depSpikes )
    spikeInitLine = plot( depSpikes(i).spikeTimeMs, depSpikes(i).spikeThreshold, 'ro' );
  end
  
  % plot min points hyp traces
  minPointX = analysis.hyp.IhTime;
  minPointX = minPointX + analysis.hyp.stimTimes(:, 1)';
  minPointY = analysis.hyp.IhMin;
  minPointLine = plot( minPointX, minPointY, 'mo' );
  minPointLine.Color = [0, 0.7, 0];
  
  % plot tau points
  for i=1:numel( analysis.hyp.hyperpolarizingStepIndices )
    trace = analysis.rawTraces(:, analysis.hyp.hyperpolarizingStepIndices(i));
    tauLine = plot( analysis.hyp.tauSample(i)/analysis.samplesPerMs, trace(analysis.hyp.tauSample(i)), 'bo' );
    tauLine.Color = [0.9, 0.4, 0.9];
  end
  
  % plot steady state points
  for i=1:numel( analysis.hyp.steadyState )
    steadyX = [0.5*(analysis.hyp.stimTimes(i, 2) - analysis.hyp.stimTimes(i, 1)) + analysis.hyp.stimTimes(i, 1), analysis.hyp.stimTimes(i, 2)];
    steadyY = [analysis.hyp.steadyState(i), analysis.hyp.steadyState(i)];
    steadyStateLine = plot( steadyX, steadyY, 'k-' );
  end
  
  % make it purdy
  f.Name = analysis.cellId;
  title( analysis.cellId )
  f.Color = 'white';
  ylabel( 'Membrane Potential (mV)' )
  xlabel( 'Time (ms)' )
  legend( [dataLine(1), spikeInitLine, minPointLine, tauLine, steadyStateLine], ...
    {'Memb. Potential', 'Spike Initiation', 'Peak Hyp. Deflection', 'Time Constant', 'Steady State'} )
  
  % set axis window
  beginWindow = 0;
  leftStim = min( analysis.hyp.stimTimes(:,1) );
  rightStim = max( analysis.hyp.stimTimes(:,2) );
  endWindow = max( time );
  bottomWindow = min( min( analysis.rawTraces ) ) - 3;
  topWindow = max( max( analysis.rawTraces ) ) + 3;
  axis( [beginWindow, ((endWindow-rightStim)/2+rightStim), bottomWindow, topWindow] ) % because it just 
  % fucking looks off-center, that's why
  
end