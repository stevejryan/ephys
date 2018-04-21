function [spikeStruct, options] = ComputeSpikeShapeParameters( trace, samplesPerMs, spikeStartIndices, varargin )
  % use an inputParser object to parse options passed in from above
  optionParser = inputParser();
  optionParser.StructExpand = true;
  optionParser.KeepUnmatched = true;
  % window of time after end of spike to look for a fast AHP.  This also
  % determines the window used for the mAHP, which picks up where this one
  % leaves off
  optionParser.addParameter( 'fAhpWindow', [0 0] );
  % turn on debugging plots
  optionParser.addParameter( 'debugPlots', true )
  % pass to a function to do a little extra parsing
  options = parseOptions( optionParser, varargin{:} );
  
  spikeStruct = CreateSpikeStruct( numel( spikeStartIndices ) );
  if numel( spikeStartIndices ) == 0
    return;
  end
  
  for spikeNum = 1:numel( spikeStartIndices )
    spikeStruct.spikeInitIndex(spikeNum) = spikeStartIndices(spikeNum);
    spikeStruct.spikeTimeMs(spikeNum) = spikeStartIndices(spikeNum) / samplesPerMs;
    spikeStruct.spikeThreshold(spikeNum) = trace( spikeStartIndices(spikeNum) );
    eventStart = spikeStartIndices(spikeNum) - options.preSpikePeriod*samplesPerMs;
    eventStop = spikeStartIndices(spikeNum) + options.postSpikePeriod*samplesPerMs;
    spikeStruct.spikeWaveforms(:, spikeNum) = trace(eventStart:eventStop);
    if (spikeStartIndices(spikeNum)+options.spikeWindow) > length( trace )
      % protection against some unusual cases where options.spikeWindow
      % gets set to a large number
      options.spikeWindow = length( trace ) - spikeStartIndices(spikeNum);
    end
    spikePeak = max( trace(spikeStartIndices(spikeNum):spikeStartIndices(spikeNum)+options.spikeWindow) );
    spikeStruct.spikePeak(spikeNum) = spikePeak;
    spikeStruct.height(spikeNum) = spikePeak - spikeStruct.spikeThreshold(spikeNum);
  end
  
  spikeStruct = interpolateTimingParameters( samplesPerMs, spikeStruct, options );
  options.fAhpWindow(2) = ceil( 4 * spikeStruct(1).AP10 );
  
  spikeStruct = findDerivParameters( samplesPerMs, spikeStruct, options );
  
  spikeStruct = findAhpParameters( trace, samplesPerMs, spikeStruct, options );
  
end

% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%%
% % do interpolation to calculate widths, rise time, and decay time
% function options = computeFAhpWindow( samplesPerMs, spikeStruct, trace, options )
%   a = 5;
%   if isempty( options.fAhpWindow )
%     for i = 1:numel( spikeStruct.spikeInitIndex )
%     
%     end
%   else
%     options.fAhpWindow = [0 2];
%   end
% end
%%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%%
% do interpolation to calculate widths, rise time, and decay time
function spikeStruct = interpolateTimingParameters( samplesPerMs, ...
  spikeStruct, options )
  
  for i = 1:numel( spikeStruct.spikeInitIndex )
    height = spikeStruct.height(i);
    spike = spikeStruct.spikeWaveforms(:,i);
    spike(1:options.preSpikeSamples) = [];
%     [~, peak] = max( spike );
    peak = find( spike == spikeStruct.spikePeak(i), 1, 'first' );
    spikeEndInd = find( spike(peak:end) < spikeStruct.spikeThreshold(i), 1, 'first' ) + peak - 1;
    spike(spikeEndInd+1:length( spike )) = [];
    % this shitty line right here is necessary to help interp1 not
    % occasionally throw errors about non-unique points.  eps is on the
    % order of E-16, so 100 eps is still waaaaay below the noise floor and
    % won't affect extracted features.
    spike = spike + (100*eps*(1:numel( spike )))';
%     [~, peak] = max( spike );
    fractionsOfInterest = [0.1, 0.2, 0.5, 0.8, 0.9];
    fractionSamples = NaN( 2, numel( fractionsOfInterest ) );
    for fraction = 1:numel( fractionsOfInterest )
      fractionHeight = fractionsOfInterest(fraction)*height + ...
        spikeStruct.spikeThreshold(i);
      Vq = interp1( spike(1:peak), 1:peak, fractionHeight );
      fractionSamples(1, fraction) = Vq; % still measured in samples
      
      Vq = interp1( spike(peak+1:end), peak+1:length( spike ), fractionHeight );
      fractionSamples(2, fraction) = Vq; % still measured in samples
    end
    fractionTimes = fractionSamples ./ samplesPerMs; % convert to ms
    
    % this assumes 10 and 90 will remain the lowest and highest fractions
    % computed here
    spikeStruct.riseTime(i) = fractionTimes(1,end) - fractionTimes(1,1);
    spikeStruct.decayTime(i) = fractionTimes(2,1) - fractionTimes(2,end);
    
    % Iterate through fractions and store values in spike struct
    % this will fail if the appropriate field is not added in
    % CreateSpikeStruct.m
    for fraction = 1:numel( fractionsOfInterest )
      spikeStruct.(sprintf( 'AP%s', num2str( 100*fractionsOfInterest(fraction) ) ))(i) ...
        = fractionTimes(2, fraction) - fractionTimes(1, fraction);
    end
  end
  
end

%%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%%
% Compute first and second derivatives then assign parameters from these
% traces to spikeStruct
function spikeStruct = findDerivParameters( samplesPerMs, spikeStruct, options )
  for i = 1:numel( spikeStruct.spikeInitIndex )
    f = spikeStruct.spikeWaveforms(:,i);
    f1 = diff( f ) * samplesPerMs; % should put f1 in mV/ms
    f2 = [0; diff( f1 ); 0] * samplesPerMs; % should put f2 in mV/ms^2
    
    % define a search window for post-peak derivative values.  We could use
    % 'end', but it might run into other spike waveforms.
    if i < numel( spikeStruct.spikeInitIndex )
      % we're not on the last spike yet
      if (spikeStruct.spikeInitIndex(i+1) - spikeStruct.spikeInitIndex(i)) ...
          < options.postSpikeSamples
        % the next spike is likely in this window  
        [~, peak] = max( f(1:spikeStruct.spikeInitIndex(i+1) - spikeStruct.spikeInitIndex(i) + options.preSpikeSamples) );
        postSpikeDerivWindow = spikeStruct.spikeInitIndex(i+1) - ...
          spikeStruct.spikeInitIndex(i) + options.preSpikeSamples; % - peak 
      else
        [~, peak] = max( f );
        postSpikeDerivWindow = length( f1 );
      end
    else
      [~, peak] = max( f );
      postSpikeDerivWindow = length( f1 );
    end

    [preMaxDeriv, preMaxDerivInd] = max( f1(1:peak) );
    % the extra 0.5 compensates for the downsampling in the transition from
    % f -> f1
    preMaxDerivTime = (preMaxDerivInd - options.preSpikeSamples - 0.5) ...
      / samplesPerMs;
    
    [preMaxConcavity, preMaxConcavityInd] = max( f2(1:peak) );
    preMaxConcavityTime = (preMaxConcavityInd - options.preSpikeSamples - 1) ...
      / samplesPerMs;
    
    [preMinConcavity, preMinConcavityInd] = min( f2(1:peak) );
    preMinConcavityTime = (preMinConcavityInd - options.preSpikeSamples) ...
      / samplesPerMs;
    
    [postMinDeriv, postMinDerivInd] = min( f1(peak:postSpikeDerivWindow) );
    postMinDerivTime = ((peak - options.preSpikeSamples - 1) + (postMinDerivInd - 0.5)) ...
      / samplesPerMs;
    
    [postMaxConcavity, postMaxConcavityInd] = max( f2(peak+1:postSpikeDerivWindow) );
    postMaxConcavityTime = (postMaxConcavityInd + peak - options.preSpikeSamples - 1) ...
      / samplesPerMs;
    
    spikeStruct.preMaxDeriv(i)          = preMaxDeriv;
    spikeStruct.preMaxDerivTimes(i)     = preMaxDerivTime;
    spikeStruct.preMaxConcavity(i)      = preMaxConcavity;
    spikeStruct.preMaxConcavityTime(i)  = preMaxConcavityTime;
    spikeStruct.preMinConcavity(i)      = preMinConcavity;
    spikeStruct.preMinConcavityTime(i)  = preMinConcavityTime;
    spikeStruct.postMinDeriv(i)         = postMinDeriv;
    spikeStruct.postMinDerivTime(i)     = postMinDerivTime;
    spikeStruct.postMaxConcavity(i)     = postMaxConcavity;
    spikeStruct.postMaxConcavityTime(i) = postMaxConcavityTime;
    
  end
    
end

%%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%%
% fine appropriate points corresponding to fAHP and mAHP
function spikeStruct = findAhpParameters( trace, samplesPerMs, spikeStruct, options )
  
  for i=1:numel( spikeStruct.spikeInitIndex )
    if i < numel( spikeStruct.spikeInitIndex )
      % if there's another spike after this one, we can make the somewhat
      % liberal assumption that the AHP could be anywhere between this
      % spike and the next.  
      spike = trace(spikeStruct.spikeInitIndex(i):spikeStruct.spikeInitIndex(i+1));
    else
      if (length( trace ) - spikeStruct.spikeInitIndex(i)) > 250*samplesPerMs
        % alternatively, if there's no subsequent spike, we'll proceed on
        % the somewhat conservative assumption that any AHP is within 250
        % ms.
        spike = trace(spikeStruct.spikeInitIndex(i):spikeStruct.spikeInitIndex(i)+250);
      else
        spike = trace(spikeStruct.spikeInitIndex(i):end);
      end
    end

    [~, peak] = max( spike );
    if length( spike ) >= peak+options.fAhpWindow(2)*samplesPerMs
      fAhpTrace = spike(peak+options.fAhpWindow(1)*samplesPerMs:peak+options.fAhpWindow(2)*samplesPerMs);
      mAhpTrace = spike(peak+options.fAhpWindow(2)*samplesPerMs:end);
    else
      fAhpTrace = spike(peak+options.fAhpWindow(1)*samplesPerMs:end);
      mAhpTrace = NaN;
    end
    
    [fAhpAbs, fAhpInd] = min( fAhpTrace );
    fAhp = fAhpAbs - spikeStruct.spikeThreshold(i);
    fAhpTime = (fAhpInd + peak - 1) / samplesPerMs;
    [mAhpAbs, mAhpInd] = min( mAhpTrace );
    if isnan( mAhpAbs )
      mAhpInd = NaN;
    end
    mAhpTime = (mAhpInd + peak - 1) / samplesPerMs;
    mAhp = mAhpAbs - spikeStruct.spikeThreshold(i);
    
    spikeStruct.fAHP(i) = fAhp;
    spikeStruct.fAHPAbsolute(i) = fAhpAbs;
    spikeStruct.fAHPTime(i) = fAhpTime;
    spikeStruct.mAHP(i) = mAhp;
    spikeStruct.mAHPAbsolute(i) = mAhpAbs;
    spikeStruct.mAHPTime(i) = mAhpTime;
  end
end

%%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%%
% sequester the code for parsing input into this function down here
function options = parseOptions( parser, varargin )
  % doesn't need to be stored, obj is persistent
  parser.parse( varargin{:} );
  % collect results of parsing into options object.  This excludes any
  % unmatched fields
  options = parser.Results;
  % collect any unmatched fields and assign them to normal fields.  These
  % may be useless, but this is the conservative, forward-thinking thing to
  % do in case functions at lower levels of hierarchy need options passed
  % form multiple layers above.
  UnmatchedFields = fieldnames( parser.Unmatched );
  for i=1:numel( UnmatchedFields )
    options.(UnmatchedFields{i}) = parser.Unmatched.(UnmatchedFields{i});
  end
end