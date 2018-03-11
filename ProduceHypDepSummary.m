function summaryRow = ProduceHypDepSummary( analysis )

  varNames = {'IhRatio', 'IAR', 'Tau', 'Rin', 'ISI1', 'ISIN', 'ISI1overN', ...
    'fAHP', 'fAHPTime', 'mAHP', 'mAHPTime'};
  summaryRow = array2table( NaN( 1, numel( varNames ) ), 'VariableNames', varNames );
  catSpikes = concatenateSpikeStruct( analysis );

  summaryRow.IhRatio = analysis.hyp.IhRatio(1);
  summaryRow.IAR = analysis.hyp.IAR;
  summaryRow.Tau = analysis.hyp.tau(end);
  summaryRow.Rin = analysis.hyp.Rin(end);
  summaryRow.ISI1 = nanmedian( analysis.dep.firstIsi );
  summaryRow.ISIN = nanmedian( analysis.dep.lastIsi );
  summaryRow.ISI1overN = nanmedian( analysis.dep.firstIsi ./ analysis.dep.lastIsi );
  summaryRow.fAHP = nanmedian( catSpikes.fAHP );
  summaryRow.fAHPTime = nanmedian( catSpikes.fAHPTime );
  summaryRow.mAHP = nanmedian( catSpikes.mAHP );
  summaryRow.mAHPTime = nanmedian( catSpikes.mAHPTime );

  summaryRow.Row = {analysis.cellId};

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