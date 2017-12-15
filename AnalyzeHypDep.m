function analysis = AnalyzeHypDep( filename, varargin )
  % use an inputParser object to parse options passed in from above
  optionParser = inputParser();
  optionParser.StructExpand = true;
  optionParser.KeepUnmatched = true;
  % length of time after spike to keep for eventStack (in ms)
  optionParser.addParameter( 'postSpikePeriod', 20 );
  % length of time before spike to keep for eventStack (in ms)
  optionParser.addParameter( 'preSpikePeriod', 1 );
  % which amplifier channel to draw from
  optionParser.addParameter( 'ampChannel', 0 );
  % flag to produce a summary table row for a larger analysis
  optionParser.addParameter( 'produceSummaryTable', true );
  % pass to a function to do a little extra parsing
  options = parseOptions( optionParser, varargin{:} );
  
  % parse cellId from filename
  [~, justTheFileName, ~] = fileparts( filename );
  cellId = strsplit( justTheFileName, '_' );
  cellId = cellId{1};
  cellId = strrep( cellId, ' ', '' );
  % initialize analysis struct object
  analysis = struct( 'filename', filename, 'cellId', cellId, ...
    'datetime', datetime( 'now' ) );
  
  % pull data from abf file using abfload
  % https://github.com/fcollman/abfload
  % data is a [samples X ampChannels X episodes] matrix
  % sampleInterval is in microseconds
  % header is a structure of descriptive information
  [abfData, sampleInterval, header] = abfload( filename );
  abfStim = BuildStimFromHeader( header, sampleInterval, options.ampChannel );
  abfData = squeeze( abfData(:, options.ampChannel+1, :) ); % strip away other dimensions
  analysis.rawTraces = abfData;
  sampleInterval = sampleInterval / 1000; % convert to milliseconds
  samplesPerMs = 1 / sampleInterval;
  numberOfEpisodes = header.lActualEpisodes;
  analysis.header = header;
  analysis.stimWaveform = abfStim;
  analysis.samplesPerMs = samplesPerMs;
  
  % iterate through episodes of data collecting spike information
  for episode = 1:numberOfEpisodes
    % trace holds a single sweep of ephys data from the protocol
    trace = abfData(:, episode);
    % eventDetect is the spike detector.  Tends to be fairly liberal.
    [spikeStartIndices, options] = DetectSpikes( trace, samplesPerMs, options );
    
    [spikeStruct(episode), options] = ComputeSpikeShapeParameters( trace, ...
      samplesPerMs, spikeStartIndices, options );
  end
  analysis.spikes = spikeStruct;
  
  % process the protocol information to separate spikes into stimulated and
  % non-stimulated, build FI data, ISIs
  [analysis.dep, options] = ProcessDepolarizingHypDepSteps( analysis, abfStim, samplesPerMs, options );

  % at some point we'll have to analyze the hyperpolarizing traces
  [analysis.hyp, options] = ProcessHyperpolarizingHypDepSteps( analysis, abfStim, samplesPerMs, options );
  
  % Create and store summary row as table in analysis object.  Desirable if
  % you're analyzing a large number of hypdeps simultaneously and you want
  % to produce a summary table by concatenating a large number of analysis
  % objects
  analysis.summary = ProduceHypDepSummary( analysis );
  analysis.options = options;
  disp( 'milkshake' )

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