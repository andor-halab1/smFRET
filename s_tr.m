%% Use this code to go through all traces and select the good ones.
%  a 10r-ng-10r illumination pattern should be strictly followed.
%  Use 's' to save individual RAW traces as .dat files.
%  Use 'b' to go to the previous molecule, and 'g' to go to a specific molecule.

function s_tr()
close all;
fclose('all');

%% Read data
pth=input('directory [default=C:\\User\\tir data\\yyyy\\New Folder]  ');
if isempty(pth)
    disp('error');
end
cd(pth);
save_file=pth;

fname=input('index # of filename [default=1]  ');
if isempty(fname)
    fname=1;
end
fname=num2str(fname);
disp(['hel' fname '.traces']);

timeunit=input('time unit [default=0.075 sec]  ');
if isempty(timeunit)
    timeunit=0.075;
end

%select the folder to which the files need to be saved
newfolder = [fname ' selected traces'];
mkdir(newfolder);

fid=fopen(['hel' fname '.traces'],'r');

%first line of binary file specifies length of trace
len=fread(fid,1,'int32');
disp('The len of the time traces is: ')
disp(len);

%number of traces
Ntraces=fread(fid,1,'int16');
disp('The number of traces is: ')
disp(Ntraces/2);

%raw is a linear array, looks like it
raw=fread(fid,Ntraces*len,'int16');
disp('Done reading data.');
fclose(fid);

selection=input('spots selected using frame 1-10-[1], frame 11-20-[2], or frame 1-20-[12]  ');
if selection == 1
    startFrame = 12;
else
    startFrame = 2;
end

%alpha
LEAKAGE=0.0;

%convert into traces
index=(1:Ntraces*len);
Data=zeros(Ntraces,len);
Data(index)=raw(index);

rdonor=zeros(Ntraces/2,len);
racceptor=zeros(Ntraces/2,len);
total=zeros(Ntraces/2,1);
for i=1:(Ntraces/2)
    rdonor(i,:)=Data(i*2-1,:);
    racceptor(i,:)=Data(i*2,:);
    tempD=sum(rdonor(i,(startFrame:startFrame+7)),2);
    tempA=sum(racceptor(i,(startFrame:startFrame+7)),2);
    total(i)=(tempD+tempA)/8.; 
end

%% Rough rejection of singly labelled species
disp('use intensity to remove singly labelled species');
figure;
hist(total,-100:10:2000);
grid on;
zoom on;
xlabel('Intensity of the selected frames');
ylabel('Counts');

fcutoff1=input('intensity low cutoff: ','s');
cutoff1=str2num(fcutoff1);
if isempty(cutoff1)
    cutoff1=300;
end
fcutoff2=input('intensity high cutoff: ','s');
cutoff2=str2num(fcutoff2);
if isempty(cutoff2)
    cutoff2=1000;
end

index=logical((total < cutoff1)+(total > cutoff2));
rdonor(index,:)=[];
racceptor(index,:)=[];

N_mol=size(rdonor,1);
disp(['there are ' num2str(N_mol) ' traces']);

%% View remaining baseline intensities after photobleaching
for i=1:N_mol
    tD(i)=sum(rdonor(i,(end-18:end-11)),2)/8.;
    tA(i)=sum(racceptor(i,(end-18:end-11)),2)/8.;
end

figure;
ax1=subplot(2,1,1);
hist(tD,-100:2:2000);
grid on;
zoom on;
xlabel('Intensity in the Cy3 channel of the second last 10 frames');
ylabel('Counts');
axis tight;
temp=axis;
temp(1)=-10;
temp(2)=100;
axis(temp);
ax2=subplot(2,1,2);
hist(tA,-100:2:2000);
grid on;
zoom on;
xlabel('Intensity in the Cy5 channel of the second last 10 frames');
ylabel('Counts');
% axis tight;
% temp=axis;
% temp(1)=-10;
% temp(2)=100;
% axis(temp);
linkaxes([ax1,ax2],'x');
linkaxes([ax1,ax2],'y');
[X,~]=ginput(2);
donor_blank=X(1);
acceptor_blank=X(2);

% plot(tD,tA,'x');
% axis square;
% temp=axis;
% temp(1)=0;
% temp(3)=0;
% temp(2)=max(temp(2),temp(4));
% temp(4)=temp(2);
% axis(temp);
% grid on;
% zoom on;
% xlabel('Intensity in the Cy3 channel');
% ylabel('Intensity in the Cy5 channel');
% [donor_blank,acceptor_blank]=ginput(1);

disp(donor_blank);
disp(acceptor_blank);
donor=rdonor-donor_blank;
acceptor=racceptor-acceptor_blank;

%% View traces
hdl=figure;
i=0;
time=(0:(len-1))*timeunit;
while (N_mol-i) > 0
    i = i+1 ;
    
    %trace window
    figure(hdl);
    ax1=subplot(2,1,1);
    plot(time,donor(i,:),'g', time,acceptor(i,:)-LEAKAGE*donor(i,:),'r', time,donor(i,:)+acceptor(i,:)-LEAKAGE*donor(i,:)+400,'k');
    title(['  Molecule ' num2str(i) ' of ' num2str(N_mol)]);
    axis tight;
    temp=axis;
    temp(3)=-temp(4)*0.2;
    temp(4)=temp(4)*1.1;
    if temp(4) < 500
        temp(4)=500;
    end
    axis(temp);
    grid on;
    zoom on;
    
    ax2=subplot(2,1,2);
    fretE=(acceptor(i,:)-LEAKAGE*donor(i,:))./(donor(i,:)+acceptor(i,:)-LEAKAGE*donor(i,:));
    %this is to avoid undefined fretE
    for m=1:len
        if donor(i,:)+acceptor(i,:)-LEAKAGE*donor(i,:)<=0
            fretE(m)=-0.2;
        end
    end
    fretE(fretE>1.2)=1.2;
    fretE(fretE<-0.2)=-0.2;
    plot(time,fretE,'b');
    axis tight;
    temp=axis;
    temp(3)=-0.2;
    temp(4)=1.2;
    axis(temp);
    linkaxes([ax1,ax2],'x');
    grid on;
    zoom on;

    answer=input('press b-back,g-go,s-save  ','s');
    
    if answer=='b'
        i=i-2;
    end

    if answer=='g'
        mol= input('which molecule do you choose:  ');
        i= mol-1;
    end
    
    %to save individual traces
    if answer=='s'
        output=[time' rdonor(i,:)' racceptor(i,:)'];
        save([save_file '\' newfolder  '\hel' fname '_tr' num2str(i) '.dat'],'output','-ascii');
    end
end

close all;
fclose('all');


