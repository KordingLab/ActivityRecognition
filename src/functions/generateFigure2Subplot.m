function generateFigure2Subplot(data,index,subVec)

subplot(subVec(1),subVec(2),subVec(3));
x = data{index}(1,:) - min(data{index}(1,:));
plot(x,data{index}(2:4,:)')
axis([0 2 -20 20]);