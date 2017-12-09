function stimChannel = BuildStimFromHeader( h, si, channel )
  % Inputs:
  %    h: select parameters from abf file header 
  %   si: sampling interval in microseconds
  %
  % Outputs:
  %   Some stuff I guess

  channel = channel + 1; % PClamp channels index from 0, matlab indexes from1
  DACEpoch = h.DACEpoch(channel);
  numEpisodes = h.lActualEpisodes;
  numEpochs = numel( DACEpoch.nEpochType );
  epochLengthInPts = h.dataPtsPerChan;
  si = si / 1000; % convert si to milliseconds

  % loop over episodes
  % Have to loop over episodes first instead of epochs because epochs aren't
  % guaranteed to be the same duration, which would make it difficult to
  % concatenate them
  allEpisodes = zeros( epochLengthInPts, numEpisodes );
  for episode=1:numEpisodes
    singleEpisode = [];
    for epoch = 1:numEpochs
      epochType = DACEpoch.nEpochType(epoch);
      if epochType == 1
        % Step
        stepDur = DACEpoch.lEpochInitDuration(epoch) + (episode-1)*DACEpoch.lEpochDurationInc(epoch);
        stepAmp = DACEpoch.fEpochInitLevel(epoch) + (episode-1)*DACEpoch.fEpochLevelInc(epoch);
        singleEpoch = stepAmp*ones( 1, stepDur );
      elseif epochType == 2
        % ramp
        warning( 'Steve''s a lazy shit and hasn''t written this part yet' )
      else
        % unknown
        warning( 'Epoch type %s unknown', num2str( epochType ) )

      end
      singleEpisode = [singleEpisode, singleEpoch];
      clear singleEpoch
    end
    singleEpisode = horzcat( zeros( 1, DACEpoch.firstHolding ), singleEpisode );
    singleEpisode = horzcat( singleEpisode, zeros( 1, epochLengthInPts - numel( singleEpisode ) ) );
    allEpisodes(:,episode) = singleEpisode';
    clear singleEpisode
  end
  stimChannel = allEpisodes;

end