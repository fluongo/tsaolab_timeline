function [outputArg1,outputArg2] = quick_plot(x,y)
%QUICK_PLOT Summary of this function goes here
%   Detailed explanation goes here

nChannels = size(y, 2);
rng(1);
colors = rand(8, 3);
for i = 1:nChannels
    subplot(nChannels, 1, i); plot(x, y(:,i), 'Color',colors(i,:));
    title(sprintf('Channel %d', i)); ylim([-0.5 5.5])
end

end

