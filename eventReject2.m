function [eventStarts eventThresh eventStack numEvents] = eventReject2(eventLength, eventStarts, eventThresh, jumpLead, jumpTail, samplesPerMs, preSamples, postSamples, data, episode, windowMult)

eventStack = zeros(uint16(eventLength),1);
numEvents = length(eventStarts);

%if these parameters are entered as 0, the script will continue to run
%essentially as though they don't matter.
if (jumpLead == 0)
    jumpTail = length(data);
    jumpLead = 1;
end

if(eventStarts ~= 0)
    count = 0;
    for i=1:numEvents
        
        
        %If the event starts after the end of the defined current
        %injection, it gets rejected
        if (eventStarts(i)*samplesPerMs > jumpTail)
%             disp('after current step')
            eventStarts(i) = 0; %tags this index for elimination
            eventThresh(i) = 0;
            
        %If the event starts before the beginning of the current injection,
        %it gets rejected
        elseif (eventStarts(i)*samplesPerMs < jumpLead) 
%             disp('before current step')
            eventStarts(i) = 0; %tags this index for elimination
            eventThresh(i) = 0; 
            
        %If the event starts close enough to the end of the trace that
        %there aren't at least {postSamples} samples after it, the event
        %gets rejected as well.  This is mostly because the next stage
        %needs those samples to evaluate the peak, and generates an error
        %if they're not there
        elseif ((length(data(:,episode)) - eventStarts(i)*samplesPerMs) <= postSamples)
%             disp('close to the end')
            eventStarts(i) = 0;
            eventThresh(i) = 0;
   
        %Similar to above, some applications of this script require a large
        %number of preSamples.  If the spike is too close to the beginning
        %of the trace, it's rejected to avoid errors.
        elseif (eventStarts(i)*samplesPerMs <= preSamples)
%             disp('close to the beginning')
            eventStarts(i) = 0;
            eventThresh(i) = 0;
            
        %If the event doesn't cross a threshold value within a specified 
        %window after spike initiation, it gets rejected as well.  This 
        %window is 1 ms + 2 samples by default, but can be expanded or 
        %contracted using the windowMult parameter, which defaults to 1 but
        %can be set in the function call.
        else             
            event = data((eventStarts(i)*samplesPerMs-preSamples):(eventStarts(i)*samplesPerMs+postSamples),episode);
            
            if (max(event((preSamples+1):(preSamples+windowMult*samplesPerMs + 2))) > -10)
%                 disp('crosses -10')
                count = count + 1;
                eventStack(:,count) = event; %Saved!
                event = 0;
            else
%                 disp('doesnt cross -10')
                eventStarts(i) = 0; %tags this index for elimination
                eventThresh(i) = 0;
            end
        end
    end
    
    %Sometimes the detection algorithm makes mutliple detections for a
    %single spike.  This for-loop steps backwards through the remaining
    %eventStarts and eliminates an event if the nearest one directly before
    %it is closer than 3ms.  The assumption is implicit that the earliest
    %event detected for any given spike is the correct one.
    for j=numEvents:-1:2
        if (eventStarts(j) - eventStarts(j-1)) < 3
            eventStarts(j) = 0;
            eventThresh(j) = 0;
        end
    end
end

% Strip Zeros
eventStarts = eventStarts((eventStarts~=0)); %scrub tagged/zeroed elements from the array
eventThresh = eventThresh((eventThresh~=0));
numEvents = length(eventStarts);
end