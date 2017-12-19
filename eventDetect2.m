function [eventStarts eventThresh] = eventDetect2(trace,samplesPerMs)%,spikeSlopeThresh,use)%,fAHPThresh)
%[eventStarts eventThresh] = eventDetect2(trace,samplesPerMs)
%
%eventDetect analyzes a voltage trace to determine where putative 
%spike-initiation sites are, and returns a pair of vectors.
%
%-trace is a single sweep/episode/trace of intracellular recording that
%putatively contains spikes.  
%-samplesPerMs is # of samples per ms
%
%-eventStarts contains the start-time (in ms) of each putative event
%-eventThresh contains the membrane potential at each of these putative
% %events (in the same order, for consistency)
% 
% dllname = 'P:\Steve\Data\axon\SourceCode\AxonDev\Comp\AxAbfFio32\abffio.dll';
% % filename = 'R310108_0001.abf';
% filename = 'D01040109_0004.abf';
% channel = 0;
% [data, times, npoints, s]=ABFGetADCChannel(dllname, filename, channel);
% trace=data(:,4);
% samplesPerMs = 10;
% episode = 4;

f = trace;
f1 = zeros(1,length(f)-1);
f2 = zeros(1,length(f1)-1);

% for i=2:length(f)
%     f1(i-1) = f(i) - f(i-1);
% end
f1 = f(2:end) - f(1:end-1);

f1s = smooth(f1,3);

% for i=2:length(f1)
%     f2(i-1) = f1(i) - f1(i-1);
% end
f2 = f1(2:end) - f1(1:end-1);

f2s = smooth(f2,3);
f2sMean = mean(f2s);
f2sSTD = std(f2s);
threshold = f2sMean + 2*f2sSTD;
% disp('four sds')

% t0=1:length(f);
% t1 = 1.5:1:24999.5;
% t2 = 2:24999;
f1s = f1s';
f2s = f2s';

% This sequence looks for local maxima in the second derivative (f2) that
% are associated with positive slopes and marks them as potential event
% initiation points

count = 0;
times = 0;
for i=2:length(f2s)-2;
    if (f2s(i) > threshold)         
        if (f2s(i) > f2s(i-1))
            if (f2s(i) < f2s(i+1))
                if (f1s(i) > 0)
                    count = count + 1;
                    times(count) = i;
                end
            end
        end
    end
end

% This is a cleanup step to catch any places where multiple initiations are
% detected within a very close range of one another.  This filter is fairly
% liberal, and events generated here will be run through eventReject for
% more strenuous filtering
times2 = times;
count = 1;
for j=1:length(times)
    if (count ~= j)
        if (abs(times(count) - times(j)) < 2*samplesPerMs)
            times2(j) = 0;
        else
            count = j;
        end        
    end
end

%+1 compensates for the difference in indexing between second derivative
%and raw trace
% "find(times2~=0) allows it to ignore times that were eliminated above
eventStarts = (times2(find(times2~=0))+1)/samplesPerMs;
eventThresh = f(eventStarts*samplesPerMs);