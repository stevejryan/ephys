function varargout = AnalyzeFolderOfHypDeps( directory, varargin )
  % use an inputParser object to parse options passed in from above
  optionParser = inputParser();
  optionParser.StructExpand = true;
  optionParser.KeepUnmatched = true;
  % default value for amplifier channel
  optionParser.addParameter( 'ampChannel', 0 );
  % flag to save individual mat files
  optionParser.addParameter( 'saveMatFile', true );
  % flag to save summary spreadsheet and mat file
  optionParser.addParameter( 'produceSummaryTable', true );
  % produce summary plots, still working on these
  optionParser.addParameter( 'summaryPlots', false );
  % pass to a function to do a little extra parsing
  options = parseOptions( optionParser, varargin{:} );
  
  cd( directory )
  abfList = dir( '*.abf' );
  summary = [];
  for file = 1:numel( abfList )
    analysis(file) = AnalyzeHypDep( abfList(file).name, options );
    summary = concatenateSummaryTables( summary, analysis(file).summary );
  end
  if options.produceSummaryTable
    writetable( summary, 'Summary.xls', 'WriteRowNames', true )
    save( 'analysis.mat', 'analysis', 'summary' )
  end
  if nargout == 2
    varargout = {analysis, summary};
  else
    varargout = {summary};
  end
end

%%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%% %%%
% helper function for ensuring properties of summary table
function summary = concatenateSummaryTables( summary, newTable )
  if ~isempty( summary ) && ismember( newTable.Row, summary.Properties.RowNames )
    allRowNames = vertcat( summary.Properties.RowNames, newTable.Row );
    allRowNames = matlab.lang.makeUniqueStrings( allRowNames );
    newRowName = allRowNames(end);
    newTable.Row = newRowName;
  end
  summary = vertcat( summary, newTable );
end % helper function

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