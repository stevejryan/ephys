function f = PlotRampSummaryFigure( analysis )
  f = figure;
  f.Position = [ 700, 300, 960, 540 ];
  a = gca;
  dt = 1 / analysis.samplesPerMs; % dt in milliseconds
  totalDuration = size( analysis.rawTraces, 1 );
  time = dt:dt:(totalDuration / analysis.samplesPerMs);
  % plot traces
  dataLine = plot( time, analysis.rawTraces, 'b-' );
  hold( a, 'on' )
  rampSpikes = analysis.dep.rampSpikes;
  % plot spike init
  for ii=1:numel( rampSpikes )
    if ~isempty( rampSpikes(ii).spikeWaveforms )
      spikeInitLine = plot( rampSpikes(ii).spikeTimeMs, rampSpikes(ii).spikeThreshold, 'ro' );
    end
  end
  
  % plot fAHP
  for ii=1:numel( rampSpikes )
    if ~isempty( rampSpikes(ii).spikeWaveforms )
      fAhpX = rampSpikes(ii).spikeTimeMs + rampSpikes(ii).fAHPTime - dt;
      fAhpY = rampSpikes(ii).fAHPAbsolute;
      fAhpLine = plot( fAhpX, fAhpY, 'go', 'MarkerFaceColor', 'green' );
    end
  end
  
  % plot mAHP
  for ii=1:numel( rampSpikes )
    if ~isempty( rampSpikes(ii).spikeWaveforms )
      mAhpX = rampSpikes(ii).spikeTimeMs + rampSpikes(ii).mAHPTime - dt;
      mAhpY = rampSpikes(ii).mAHPAbsolute;
      mAhpLine = plot( mAhpX, mAhpY, 'ko', 'MarkerFaceColor', 'black' );
    end
  end
  
  % plot spike width summaries
  widthColors = hsv;
  for ii=1:numel( rampSpikes )
    if ~isempty( rampSpikes(ii).spikeWaveforms )
      AP10_X = rampSpikes(ii).AP10_TimesMs(:,1)' + rampSpikes(ii).spikeTimeMs(1) - dt;
      AP10_Y = repmat( rampSpikes(ii).AP10_Voltage(1), size( AP10_X ) );
      AP10_Line = plot( AP10_X, AP10_Y, 'o', 'Color', widthColors( round( 0.1*size(widthColors, 1) ), : ) );
      
      AP20_X = rampSpikes(ii).AP20_TimesMs(:,1)' + rampSpikes(ii).spikeTimeMs(1) - dt;
      AP20_Y = repmat( rampSpikes(ii).AP20_Voltage(1), size( AP20_X ) );
      AP20_Line = plot( AP20_X, AP20_Y, 'o', 'Color', widthColors( round( 0.2*size(widthColors, 1) ), : ) );
      
      AP50_X = rampSpikes(ii).AP50_TimesMs(:,1)' + rampSpikes(ii).spikeTimeMs(1) - dt;
      AP50_Y = repmat( rampSpikes(ii).AP50_Voltage(1), size( AP50_X ) );
      AP50_Line = plot( AP50_X, AP50_Y, 'o', 'Color', widthColors( round( 0.5*size(widthColors, 1) ), : ) );
      
      AP80_X = rampSpikes(ii).AP80_TimesMs(:,1)' + rampSpikes(ii).spikeTimeMs(1) - dt;
      AP80_Y = repmat( rampSpikes(ii).AP80_Voltage(1), size( AP80_X ) );
      AP80_Line = plot( AP80_X, AP80_Y, 'o', 'Color', widthColors( round( 0.8*size(widthColors, 1) ), : ) );
      
      AP90_X = rampSpikes(ii).AP90_TimesMs(:,1)' + rampSpikes(ii).spikeTimeMs(1) - dt;
      AP90_Y = repmat( rampSpikes(ii).AP90_Voltage(1), size( AP90_X ) );
      AP90_Line = plot( AP90_X, AP90_Y, 'o', 'Color', widthColors( round( 0.9*size(widthColors, 1) ), :) );
    end
  end
  
  % make it purdy
  f.Name = analysis.cellId;
  title( analysis.cellId )
  f.Color = 'white';
  ylabel( 'Membrane Potential (mV)' )
  xlabel( 'Time (ms)' )
  legend( [dataLine(1), spikeInitLine, fAhpLine, mAhpLine, ...
           AP10_Line, AP20_Line, AP50_Line, AP80_Line, AP90_Line], ...
          {'Memb. Potential', 'Spike Initiation', 'Fast AHP', 'Medium AHP', ...
           'AP10 Width', 'AP20 Width', 'AP50 Width', 'AP80 Width', 'AP90 Width'} )
  
  % set axis window
  beginWindow = 0;
  leftStim = min( analysis.dep.stimTimes(1,1) );
  rightStim = max( analysis.dep.stimTimes(1,2) );
  endWindow = max( time );
  bottomWindow = min( min( analysis.rawTraces ) ) - 3;
  topWindow = max( max( analysis.rawTraces ) ) + 3;
  axis( [beginWindow, ((endWindow-rightStim)/2+rightStim), bottomWindow, topWindow] ) % because it just 
  % fucking looks off-center, that's why
  
end