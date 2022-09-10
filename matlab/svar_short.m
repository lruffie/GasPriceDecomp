%% 4. IDENTIFICATION WITH ZERO CONTEMPORANEOUS RESTRICTIONS 
%************************************************************************** 
% Identification with zero contemporaneous restrictions is achieved in two 
% steps: (1) set the identification scheme mnemonic in the structure 
% VARopt to the desired one, in this case "zero"; (2) run VARir or VARvd 
% functions. The zero contemporaneous restrictions identification example 
% is based on the replication of Stock and Watson (2001, JEP) paper
%-------------------------------------------------------------------------- 

% 4.1 Load data from Stock and Watson
%-------------------------------------------------------------------------- 
[xlsdata, xlstext] = readtable('export_normal_data.xlsx');
dates = xlstext(3:end,1);
datesnum = Date2Num(dates);
vnames_long = xlstext(1,2:end);
vnames = xlstext(2,2:end);
nvar = length(vnames);
data   = Num2NaN(xlsdata);
for ii=1:length(vnames)
    DATA.(vnames{ii}) = data(:,ii);
end
nobs = size(data,1);

% 4.2 Plot series
%-------------------------------------------------------------------------- 
% Plot all variables in DATA
FigSize(26,6)
for ii=1:nvar
    subplot(1,3,ii)
    H(ii) = plot(DATA.(vnames{ii}),'LineWidth',3,'Color',cmap(1));
    title(vnames_long(ii)); 
    DatesPlot(datesnum(1),nobs,6,'q') % Set the x-axis label dates
    grid on; 
end
SaveFigure('graphics/SW_DATA',1)
clf('reset')

% 4.3 Set up and estimate VAR
%-------------------------------------------------------------------------- 
% Select endogenous variables
Xvnames      = {'infl','unemp','ff'};
Xvnames_long = {'Inflation','Unemployment','Fed Funds'};
Xnvar        = length(Xvnames);
% Create matrices of variables to be used in the VAR
X = nan(nobs,Xnvar);
for ii=1:Xnvar
    X(:,ii) = DATA.(Xvnames{ii});
end
% Estimate VAR
det = 1;
nlags = 4;
[VAR, VARopt] = VARmodel(X,nlags,det);
% Update the VARopt structure with additional details to be used in IR 
% calculations and plots
VARopt.vnames = Xvnames_long;
VARopt.nsteps = 24;
VARopt.quality = 1;
VARopt.FigSize = [26,12];
VARopt.firstdate = datesnum(1);
VARopt.frequency = 'q';
VARopt.figname= 'graphics/SW_';

% 4.4 IMPULSE RESPONSES
%-------------------------------------------------------------------------- 
% To get zero contemporaneous restrictions set
VARopt.ident = 'short';
VARopt.snames = {'\epsilon^{1}','\epsilon^{2}','\epsilon^{MonPol}'};
% Compute IR
[IR, VAR] = VARir(VAR,VARopt);
% Compute IR error bands
[IRinf,IRsup,IRmed,IRbar] = VARirband(VAR,VARopt);
% Plot IR
VARirplot(IRbar,VARopt,IRinf,IRsup);

% 4.5 FORECAST ERROR VARIANCE DECOMPOSITION
%-------------------------------------------------------------------------- 
% Compute VD
[VD, VAR] = VARvd(VAR,VARopt);
% Compute VD error bands
[VDinf,VDsup,VDmed,VDbar] = VARvdband(VAR,VARopt);
% Plot VD
VARvdplot(VDbar,VARopt);

% 4.6 HISTORICAL DECOMPOSITION
%-------------------------------------------------------------------------- 
% Compute HD
[HD, VAR] = VARhd(VAR,VARopt);
% Plot HD
VARhdplot(HD,VARopt);
