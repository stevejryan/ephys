function summaryRow = ProduceRampSummary( analysis )

  % IH	IAR	Tau	Rin	Amplitudes	Half Widths	Rise Time 10-90%	Decay Time 90-10%	Threshold	ISI1	ISIN	ISI1/ISIN	fAHP Diff
  varNames = {'Amplitude', 'HalfWidth', 'RiseTime', 'DecayTime', ...
    'Threshold', 'AP10_Ramp', 'AP20_Ramp', 'AP80_Ramp', 'AP90_Ramp', ...
    'preMaxDeriv', 'preMaxConcavity', 'postMinDeriv', 'postMaxConcavity', ...
    'fAHP_Ramp', 'fAHPTime_Ramp', 'mAHP_Ramp', 'mAHPTime_Ramp'};
  summaryRow = array2table( NaN( 1, numel( varNames ) ), 'VariableNames', varNames );
  catSpikes = concatenateSpikeStruct( analysis );

  disp( fprintf( 'Taking nanmedian of %d spikes', numel( catSpikes.height ) ) )
  summaryRow.Amplitude = nanmedian( catSpikes.height );
  summaryRow.HalfWidth = nanmedian( catSpikes.AP50 );
  summaryRow.RiseTime = nanmedian( catSpikes.riseTime );
  summaryRow.DecayTime = nanmedian( catSpikes.decayTime );
  summaryRow.Threshold = nanmedian( catSpikes.spikeThreshold );
  summaryRow.AP10_Ramp = nanmedian( catSpikes.AP10 );
  summaryRow.AP20_Ramp = nanmedian( catSpikes.AP20 );
  summaryRow.AP80_Ramp = nanmedian( catSpikes.AP80 );
  summaryRow.AP90_Ramp = nanmedian( catSpikes.AP90 );
  summaryRow.preMaxDeriv = nanmedian( catSpikes.preMaxDeriv );
  summaryRow.preMaxConcavity = nanmedian( catSpikes.preMaxConcavity );
  summaryRow.postMinDeriv = nanmedian( catSpikes.postMinDeriv );
  summaryRow.postMaxConcavity = nanmedian( catSpikes.postMaxConcavity );
  summaryRow.fAHP_Ramp = nanmedian( catSpikes.fAHP );
  summaryRow.fAHPTime_Ramp = nanmedian( catSpikes.fAHPTime );
  summaryRow.mAHP_Ramp = nanmedian( catSpikes.mAHP );
  summaryRow.mAHPTime_Ramp = nanmedian( catSpikes.mAHPTime );

  summaryRow.Row = {analysis.cellId};

end

function catSpikes = concatenateSpikeStruct( analysis )
  listOfFields = fieldnames( analysis.spikes );
  listOfFields( strcmp( listOfFields, 'spikeWaveforms' ) ) = [];
  numFields = numel( listOfFields );
  container = cell( numFields, 1 );
  for i=1:numFields
    for j=1:numel( analysis.spikes )
      if ~isempty( analysis.spikes(j).(listOfFields{i}) )
        container{i} = horzcat( container{i}, analysis.spikes(j).(listOfFields{i})(1) );
      end
    end
  end
  catSpikes = CreateSpikeStruct( numel( container{1} ) );
  for i=1:numFields
    catSpikes.(listOfFields{i}) = container{i};
  end
end