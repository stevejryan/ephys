function [spikeStartIndices, options] = DetectSpikes( trace, samplesPerMs, varargin )
% [eventStarts eventThresh] = eventDetect2(trace,samplesPerMs)
%
% eventDetect analyzes a voltage trace to determine where putative 
% spike-initiation sites are, and returns a pair of vectors.
%
% -trace is a single sweep/episode/trace of intracellular recording that
%  putatively contains spikes.  
% -samplesPerMs is # of samples per ms
%
% -eventStarts contains the start-time (in ms) of each putative event
% -eventThresh contains the membrane potential at each of these putative
%  events (in the same order, for consistency)

  % use an inputParser object to parse options passed in from above
  optionParser = inputParser();
  optionParser.StructExpand = true;
  optionParser.KeepUnmatched = true;
  % length of time after spike to keep for eventStack (in ms)
  optionParser.addParameter( 'debugPlots', false );
  % Minimum membrane potential spikes must cross to be considered action
  % potentials ( expressed in mV )
  optionParser.addParameter( 'minSpikeHeight', -10 )
  % When sorting candidate spike locations, how large should be the window
  % to cluster a set of samples into one 'candidate'
  optionParser.addParameter( 'clusterWindow', 15 );
  % pass to a function to do a little extra parsing
  options = parseOptions( optionParser, varargin{:} );
  
  spikeStartIndices = detectSpikes( trace, options );
  
  [spikeStartIndices, options] = cleanupSpikes( trace, spikeStartIndices, samplesPerMs, options );

end

%%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%%
% find candidate spikes
function spikeStartIndices = detectSpikes( trace, options )
  f = trace;
  f1 = diff( f );
  f2 = [0; diff( f1 ); 0];
  f1s = smooth(f1,3);
  f2s = smooth(f2,3);
  f3 = diff( f2s );
  f2sMean = mean(f2s);
  f2sSTD = std(f2s);
  threshold = mean( f2s ) + 2*std( f2s );
  
  % Generates a list of candidate locations for spikes by looking for
  % places where:
  % 1. Second derivative is unusually high
  % 2. Second derivative is increasing
  % 3. First derivative is positive, so we're finding the upstroke of a
  %    spike and not the recovery / AHP
  candidateIndices = find( (f2s > threshold) & [(f3 > 0); 0 ] & ([f1s; 0] > 0) );
  candidateClusters = zeros( numel( candidateIndices ), 1 );
  cluster = 1;
  if numel( candidateClusters ) > 1
    candidateClusters(1) = cluster;
    for i=1:numel( candidateIndices ) - 1
      if (candidateIndices(i+1) - candidateIndices(i)) <= options.clusterWindow
        % do nothing?
      else
        cluster = cluster + 1;
      end
      candidateClusters(i+1) = cluster;
    end    
  elseif numel( candidateClusters ) == 1
    candidateClusters(1) = cluster;
  end
  % clusterdata doesn't fail gracefully when you only have one data point.
  % The for loop above is... graceless, but seems to work.
%   candidateClusters = clusterdata( candidateIndices, 1 );
  numClusters = numel( unique( candidateClusters ) );
  candidatePeaks = zeros( numClusters, 1 );
  for cluster = 1:numClusters
    clusterInds = candidateIndices(candidateClusters == cluster);
    % if you want the index of the local max in the second derivative
    % [~, I] = max( f2(clusterInds) );
    % if instead you want the first index that was above threshold
    I = 1;
    candidatePeaks(cluster) = clusterInds(I);
  end
  spikeStartIndices = sort( candidatePeaks );
  
  if options.debugPlots
    figHandle = figure;
    a = gca;
    hold( a, 'on' )
    traceLine = plot( f - mean( f ), 'b-' );
    f1Line = plot( f1, 'r-' );
    f2Line = plot( f2, 'k-' );
    XLim = a.XLim;
    thresholdLine = line( XLim, [threshold, threshold] );
    line( XLim, -1*[threshold, threshold] )
    candidateLine = plot( candidateIndices, f(candidateIndices) - mean( f ), 'kx' );
    peakLine = plot( spikeStartIndices, f(spikeStartIndices) - mean( f ), 'ro' );
    legend( [traceLine, f1Line, f2Line, thresholdLine, candidateLine, ...
      peakLine], {'Raw Trace', 'f1', 'f2', 'detection threshold', ...
      'first pass candidates', 'selected candidates'} );
  end
end

%%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%%
% eliminate some spikes that probably aren't any good
function [spikeStartIndices, options] = cleanupSpikes( trace, spikeStartIndices, ...
  samplesPerMs, options )
  if numel( spikeStartIndices ) == 0
    return
  end
  postSpikeSamples = options.postSpikePeriod * samplesPerMs;
  preSpikeSamples = options.preSpikePeriod * samplesPerMs;
  options.postSpikeSamples = postSpikeSamples;
  options.preSpikeSamples = preSpikeSamples;
  % eliminate spikes so close to the beginning that there aren't enough
  % samples to look at the pre-spike period
  spikeStartIndices(spikeStartIndices < preSpikeSamples) = NaN;
  % same for the post-spike period
  spikeStartIndices((numel( trace ) - spikeStartIndices) < postSpikeSamples) = NaN;
  spikeStartIndices(isnan(spikeStartIndices)) = [];
  % Eliminate spikes that don't cross the set threshold within some period
  % after (putative) spike initiation.  First compute a window to search
  % in by looking at ISIs with a minimum of 1 ms.
  spikeStartTimes = spikeStartIndices ./ samplesPerMs;
  smallestIsi = min( diff( spikeStartTimes ) );
  smallestIsiInSamples = floor( samplesPerMs * max( [smallestIsi, 1] ) );
  for i=1:numel( spikeStartIndices )
    if (spikeStartIndices(i)+smallestIsiInSamples) <= length( trace )
      if max( trace(spikeStartIndices(i):...
          spikeStartIndices(i)+smallestIsiInSamples) ) < options.minSpikeHeight
        spikeStartIndices(i) = NaN;
      end
    else
      if max( trace(spikeStartIndices(i):end) ) < options.minSpikeHeight
        spikeStartIndices(i) = NaN;
      end
    end
  end
  % record window used for spike windowing
  options.spikeWindow = min( [1000, smallestIsiInSamples] );
  % the liberal quality of the previous filter leaves open the possibility
  % that artifacts at the beginning of the trace may be picked up as spike
  % initiation sites because a spike shortly afterwards fulfills the
  % requirement.  Oh... no, it doesn't.  Nevermind.  If it turns out I'm
  % wrong AGAIN and it DOES, then come back here and put in a requirement
  % that the integral of the trace during that period should fall within
  % bounds determined by its width, after subtracting off the baseline.
  spikeStartIndices(isnan(spikeStartIndices)) = [];
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