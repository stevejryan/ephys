function f = PlotSummaryFigure( analysis )
  f = figure;
  a = gca;
  plot( analysis.rawTraces, 'b-' )
  hold( a, 'on' )
  depSpikes = analysis.dep.depSpikes;
  for i=1:numel( depSpikes )
    plot( depSpikes(i).spikeInitIndex, depSpikes(i).spikeThreshold, 'ro' )
  end
end