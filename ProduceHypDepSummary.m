function summaryRow = ProduceHypDepSummary( analysis )

% IH	IAR	Tau	Rin	Amplitudes	Half Widths	Rise Time 10-90%	Decay Time 90-10%	Threshold	ISI1	ISIN	ISI1/ISIN	fAHP Diff
varNames = {'IH', 'IAR', 'Tau', 'Rin', 'Amplitude', 'HalfWidth', 'RiseTime', 'DecayTime', 'Threshold', 'ISI1', 'ISIN', 'ISI1overN', 'fAHP'};
summaryRow = array2table( NaN( 1, 13 ), 'VariableNames', varNames );
catSpikes = concatenateSpikeStruct( analysis );

summaryRow.IH = analysis.hyp.IhRatio(1);
summaryRow.IAR = NaN;
summaryRow.Tau = analysis.hyp.tau(1);
summaryRow.Rin = analysis.hyp.Rin(1);
summaryRow.Amplitude = nanmedian( catSpikes.height - catSpikes.spikeThreshold );
summaryRow.HalfWidth = nanmedian( catSpikes.AP50 );
summaryRow.RiseTime = nanmedian( catSpikes.riseTime );
summaryRow.DecayTime = nanmedian( catSpikes.decayTime );
summaryRow.Threshold = nanmedian( catSpikes.spikeThreshold );
summaryRow.ISI1 = nanmedian( analysis.dep.firstIsi );
summaryRow.ISIN = nanmedian( analysis.dep.lastIsi );
summaryRow.ISI1overN = nanmedian( analysis.dep.firstIsi ./ analysis.dep.lastIsi );
summaryRow.fAHP = nanmedian( catSpikes.fAHP );

end

function catSpikes = concatenateSpikeStruct( analysis )
  listOfFields = fieldnames( analysis.spikes );
  listOfFields( strcmp( listOfFields, 'spikeWaveforms' ) ) = [];
  numFields = numel( listOfFields );
  container = cell( numFields, 1 );
  for i=1:numFields
    for j=1:numel( analysis.spikes )
      container{i} = horzcat( container{i}, analysis.spikes(j).(listOfFields{i}) );
    end
  end
  catSpikes = CreateSpikeStruct( numel( container{1} ) );
  for i=1:numFields
    catSpikes.(listOfFields{i}) = container{i};
  end
end