function [ramp, options] = ProcessThresholdRamps( analysis, abfStim, samplesPerMs, options )
  thresholdStepSizes = max( abfStim );
  thresholdStepIndices = find( thresholdStepSizes ~= 0 );
  ramp.thresholdStepIndices = thresholdStepIndices;
  thresholdStepSizes = thresholdStepSizes(thresholdStepIndices);
  ramp.stepSizes = thresholdStepSizes;
  
  for episode = 1:numel( ramp.thresholdStepIndices )
    episodeIndex = ramp.thresholdStepIndices(episode);
    stimTrace = abfStim(:, episodeIndex);
    stimOn = find( stimTrace > 0, 1, 'first' );
    stimOff = find( stimTrace > 0, 1, 'last' );
    ramp.stimDurationSamples(episode) = stimOff - stimOn + 1;
    ramp.stimDurationMs(episode) = ramp.stimDurationSamples(episode) / samplesPerMs;
    spikes = analysis.spikes(episodeIndex);
    numSpikes = numel( spikes.spikeInitIndex );
    ramp.numSpikes(episode) = numSpikes;
    ramp.stimSamples(episode, :) = [stimOn, stimOff];
    ramp.stimTimes(episode, :) = [stimOn, stimOff]./samplesPerMs;
    ramp.latencyToFirstSpike(episode) = NaN;
    if numSpikes > 0
      spikeOutsideStim = false( 1, numSpikes );
      for i=1:numSpikes
        if spikes.spikeInitIndex < stimOn | spikes.spikeInitIndex > stimOff %#ok<*OR2>
          spikeOutsideStim(i) = true;
        end
      end
      spikeFields = fieldnames( spikes );
      for j=1:numel( spikeFields )
        spikes.(spikeFields{j})(:, spikeOutsideStim) = [];
      end
      ramp.latencyToFirstSpike(episode) = (spikes.spikeInitIndex(1) - stimOn) / samplesPerMs;
    end
    rampSpikes(episode) = spikes;
  end
  ramp.rampSpikes = rampSpikes;
end