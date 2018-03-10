function [dep, options] = ProcessDepolarizingHypDepSteps( analysis, abfStim, samplesPerMs, options )
  depolarizingStepSizes = max( abfStim );
  depolarizingStepIndices = find( depolarizingStepSizes ~= 0 );
  dep.depolarizingStepIndices = depolarizingStepIndices;
  depolarizingStepSizes = depolarizingStepSizes(depolarizingStepIndices);
  dep.stepSizes = depolarizingStepSizes;
  
  for episode = 1:numel( dep.depolarizingStepIndices )
    episodeIndex = dep.depolarizingStepIndices(episode);
    stimTrace = abfStim(:, episodeIndex);
    stimOn = find( stimTrace > 0, 1, 'first' );
    stimOff = find( stimTrace > 0, 1, 'last' );
    dep.stimDurationSamples(episode) = stimOff - stimOn + 1;
    dep.stimDurationMs(episode) = dep.stimDurationSamples(episode) / samplesPerMs;
    spikes = analysis.spikes(episodeIndex);
    numSpikes = numel( spikes.spikeInitIndex );
    dep.numSpikes(episode) = numSpikes;
    dep.stimSamples(episode, :) = [stimOn, stimOff];
    dep.stimTimes(episode, :) = [stimOn, stimOff]./samplesPerMs;
    dep.frequency(episode) = numSpikes / dep.stimDurationMs(episode) * 1000;
    dep.firstIsi(episode) = NaN;
    dep.lastIsi(episode) = NaN;
    dep.latencyToFirstSpike(episode) = NaN;
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
      numSpikes = numel( spikes.spikeInitIndex );
      if numSpikes > 0
        if numSpikes > 1
          dep.firstIsi(episode) = spikes.spikeTimeMs(2) - spikes.spikeTimeMs(1);
          dep.lastIsi(episode) = spikes.spikeTimeMs(end) - spikes.spikeTimeMs(end-1);
        else
          dep.firstIsi(episode) = NaN;
          dep.lastIsi(episode) = NaN;
        end
        dep.latencyToFirstSpike(episode) = (spikes.spikeInitIndex(1) - stimOn) / samplesPerMs;
      end
    end
    depSpikes(episode) = spikes;
  end
  dep.depSpikes = depSpikes;
end