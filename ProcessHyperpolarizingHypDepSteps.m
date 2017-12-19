function [hyp, options] = ProcessHyperpolarizingHypDepSteps( analysis, abfStim, samplesPerMs, options )
  hyperpolarizingStepSizes = min( abfStim );
  hyperpolarizingStepIndices = find( hyperpolarizingStepSizes ~= 0 );
  hyp.hyperpolarizingStepIndices = hyperpolarizingStepIndices;
  hyperpolarizingStepSizes = hyperpolarizingStepSizes(hyperpolarizingStepIndices);
  hyp.stepSizes = hyperpolarizingStepSizes;
  
  for episode = 1:numel( hyp.hyperpolarizingStepIndices )
    episodeIndex = hyp.hyperpolarizingStepIndices(episode);
    stimTrace = abfStim(:, episodeIndex);
    stimOn = find( stimTrace < 0, 1, 'first' );
    stimOff = find( stimTrace < 0, 1, 'last' );
    hyp.stimSamples(episode, :) = [stimOn, stimOff];
    hyp.stimTimes(episode, :) = [stimOn, stimOff]./samplesPerMs;
    hyp.stimDurationSamples(episode) = stimOff - stimOn + 1;
    hyp.stimDurationMs(episode) = hyp.stimDurationSamples(episode) / samplesPerMs;
    
    % IH 
    smoothingFactor = floor( 5*samplesPerMs/2 )*2+1; % just, empirically, 
    % this seems to work reasonably well.  Could probably go higher, 
    % especially for noisy traces, but this should be sufficient to
    % eliminate heater artifacts.  If you've got a bunch of EPSPs / IPSPs,
    % sorry, you're just boned.
    smoothTrace = smooth( analysis.rawTraces(stimOn:stimOff, episodeIndex), smoothingFactor );
    traceLength = numel( smoothTrace );
    % Assumption here that IH point is in the first half
    [IhMinPoint, IhIndex] = min( smoothTrace(1:round( traceLength / 2 )) );
    steadyState = median( smoothTrace(round( 3*traceLength/4:end )) );
    baseline(episode) = median( analysis.rawTraces(1:stimOn-1, episodeIndex) );
    hyp.IhTime(episode) = IhIndex / samplesPerMs;
    hyp.IhIndex(episode) = IhIndex + stimOn - 1;
    hyp.IhMin(episode) = IhMinPoint;
    hyp.IhRatio(episode) = (IhMinPoint - steadyState) / IhMinPoint;
    hyp.steadyState(episode) = steadyState;
    
    % input resistance
    Rin = ((IhMinPoint - baseline(episode)) / 1000) / (hyp.stepSizes(episode) / 1e12);
    hyp.Rin(episode) = Rin / 1e6; % puts Rin in Megaohms, assuming it was originally in mV and pA
    
    % time constant, 63.21%
    timeConstantTrace = smoothTrace(1:IhIndex);
    timeConstantTrace = (timeConstantTrace - timeConstantTrace(1)); 
    timeConstantTrace = timeConstantTrace ./ timeConstantTrace(end);
    aboveTimeConstant = timeConstantTrace > 0.6321;
    tauThreshold = find( aboveTimeConstant, 1, 'first' );
    hyp.tau(episode) = tauThreshold / samplesPerMs;
    hyp.tauSample(episode) = tauThreshold + stimOn - 1;
  end
  
  % IAR
  % must be at least three steps to compare
  if numel( hyp.hyperpolarizingStepIndices ) > 3
    IhMin = hyp.IhMin;
    hyp.IAR = ((IhMin(1) - baseline(1)) - (IhMin(2) - baseline(2))) / (IhMin(end) - baseline(end));
    if (hyp.stepSizes(1) - hyp.stepSizes(2)) ~= hyp.stepSizes(end)
      warning( 'Warning, IAR computation may be invalid, step sizes are irregular' )
    end
  else 
    hyp.IAR = NaN;
  end
end