%createDatafile
function datafile = createDatafile(HYP_BOOL,DEP_BOOL,THRESHOLD)

% 9-28-15 Edit
% Taking "SSPIKE" offline. We don't use that protocol anymore, so unless
% we're doing an analysis that resurrects old data or that protocol again,
% I'd prefer the simplicity of eliminating that argument from the function
% call.
SSPIKE = 0;

% SPIKE_BOOL = THRESHOLD + SSPIKE;
hyp = struct('IH',0,'IAR',0,'Rin',0,'Tau',0);
dep = struct('sweeps',{});
spike = struct([]);
thresh = struct([]);

if(~HYP_BOOL && ~DEP_BOOL && ~SSPIKE && ~THRESHOLD)
    error('You''re an idiot.');
elseif(~HYP_BOOL && ~DEP_BOOL && ~SSPIKE && THRESHOLD)
    datafile = struct('thresh',thresh);
elseif(~HYP_BOOL && ~DEP_BOOL && SSPIKE && ~THRESHOLD)
    datafile = struct('spike',spike);    
elseif(~HYP_BOOL && ~DEP_BOOL && SSPIKE && THRESHOLD)
    datafile = struct('spike',spike,'thresh',thresh);        
elseif(~HYP_BOOL && DEP_BOOL && ~SSPIKE && ~THRESHOLD)
    datafile = struct('dep',dep);           
elseif(~HYP_BOOL && DEP_BOOL && ~SSPIKE && THRESHOLD)
    datafile = struct('dep',dep,'thresh',thresh);                
elseif(~HYP_BOOL && DEP_BOOL && SSPIKE && ~THRESHOLD)
    datafile = struct('dep',dep,'spike',spike);                    
elseif(~HYP_BOOL && DEP_BOOL && SSPIKE && THRESHOLD)
    datafile = struct('dep',dep,'spike',spike,'thresh',thresh);
elseif(HYP_BOOL && ~DEP_BOOL && ~SSPIKE && ~THRESHOLD)
    datafile = struct('hyp',hyp);
elseif(HYP_BOOL && ~DEP_BOOL && ~SSPIKE && THRESHOLD)
    datafile = struct('hyp',hyp,'thresh',thresh);
elseif(HYP_BOOL && ~DEP_BOOL && SSPIKE && ~THRESHOLD)
    datafile = struct('hyp',hyp,'spike',spike);    
elseif(HYP_BOOL && ~DEP_BOOL && SSPIKE && THRESHOLD)
    datafile = struct('hyp',hyp,'spike',spike,'thresh',thresh);        
elseif(HYP_BOOL && DEP_BOOL && ~SSPIKE && ~THRESHOLD)
    datafile = struct('hyp',hyp,'dep',dep);            
elseif(HYP_BOOL && DEP_BOOL && ~SSPIKE && THRESHOLD)
    datafile = struct('hyp',hyp,'dep',dep,'thresh',thresh);                
elseif(HYP_BOOL && DEP_BOOL && SSPIKE && ~THRESHOLD)
    datafile = struct('hyp',hyp,'dep',dep,'spike',spike);                        
elseif(HYP_BOOL && DEP_BOOL && SSPIKE && THRESHOLD)
    datafile = struct('hyp',hyp,'dep',dep,'spike',spike,'thresh',thresh);
end

