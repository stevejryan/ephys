function spikeStartIndices = eventDetect2( trace, samplesPerMs, varargin )
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
  optionParser.addParameter( 'debugPlots', true );
  % When sorting candidate spike locations, how large should be the window
  % to cluster a set of samples into one 'candidate'
%   optionParser.addParameter( 'clusterWindow', 2 );
  % pass to a function to do a little extra parsing
  options = parseOptions( optionParser, varargin{:} );
  
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
  candidateIndices = find( [(f2s > threshold)] & [(f3 > 0); 0 ] & ([f1s; 0] > 0) );
  candidateClusters = clusterdata( candidateIndices, 1 );
  numClusters = numel( unique( candidateClusters ) );
  candidatePeaks = zeros( numClusters, 1 );
  for cluster = 1:numClusters
    clusterInds = candidateIndices(candidateClusters == cluster);
    [~, I] = max( f2(clusterInds) );
    candidatePeaks(cluster) = clusterInds(I);
  end
  spikeStartIndices = candidatePeaks;
  
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