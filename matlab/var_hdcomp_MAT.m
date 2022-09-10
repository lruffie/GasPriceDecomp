clear all; clear session; close all; clc
warning off all

%%%% DATA LOADING %%%%
data = readtable("export_normal_data.xlsx");

display(data.months);
%%%% DATA CLEANING %%%%

% Choose detrending option: 'log-linear' or 'HP filtering'
%detrend_opt = 'HP filtering';
%switch detrend_opt
%    case 'log-linear'
%        Y = detrend(100.*log(XXX));
%    case 'HP filtering'
%        [~,Y] = hpfilter(100.*log(XXX),1600);
%end

dates= datetime(data.months,"InputFormat","MMM yy");

months = data.months;
price_gas = data.price_gas;
price_brent_gbp = data.price_brent_gbp;
%coal = data.coal_gbp;
%OI = data.open_interest_gas;
%temp = data.temperature;
temp_deviation = data.temp_deviation;
%churn = data.churn;
%EUR = data.eurgbp;
%USD = data.gbpusd;
lng = data.lng;
storage = data.storage;
%euas = data.euas;
%supply = data.supply;

Xbis= [temp_deviation storage lng price_brent_gbp price_gas];

%data.months=[];
nobs = size(data,1);
%data.demand=[];

% Select 'true' or 'false' if you want to plot data
plot_data = false;
if plot_data
    plot(dates,data.Variables);
    legend(data.Properties.VariableNames);
end

%%%% LIB IMPORTS %%%%
% Add VAR toolbox to the MATLAB path (including all subfolders)
%folder = fileparts(which('VAR-Toolbox-main')); 

addpath(genpath('VAR-Toolbox-main'));

% OR USE DYNARE ??

Xvnames = {'temp_deviation','storage','lng','price_brent_gbp','price_gas'};
Xvnames_long = {'TempDev','Storage','LNG','Brent','Gas'};
Xnvar = length(Xvnames);


X = nan(nobs,Xnvar);
for ii=1:Xnvar
    X(:,ii) = data.(Xvnames{ii});
end
display(X)

%%%% VAR USE %%%%
const_trend = 0; %1=constant, 2=trend; 0 = no constant and no trend;
nbr_lags = 12;
[VAR, VARopt] = VARmodel(X,nbr_lags,const_trend);

VARopt.vnames = Xvnames_long;
VARopt.nsteps = 24;
VARopt.quality = 1;
VARopt.FigSize = [30,12];
%VARopt.firstdate = dates(1);
VARopt.frequency = 'm';
VARopt.figname= 'graphics/GAS_';


% Show estimated model parameters
%VAR_options.vnames = data.Properties.VariableNames;
%VARprint(VAR,VAR_options);


%%%% STRUCTURAL VAR %%%%
% Choose the identification scheme
VARopt.ident = 'short'; %'short', 'long', 'iv'        % 'oir' selects a recursive scheme, (LOOK FOR OTHER SCHEMES)
VARopt.snames = VARopt.vnames;
% Choose the horizon for the impulse responses
VARopt.nsteps = 6;
% Apply the identification scheme and compute impulse responses
[IRF,VAR] = VARir(VAR,VARopt);

%%%% IRF %%%%
% Compute confidence intervals using bootstrap methods
[IRF_lower,IRF_upper,IRF_median] = VARirband(VAR,VARopt);
% Figures related options
VARopt.savefigs = true;
VARopt.quality  = 1;
% Plot impulse response functions
VARirplot(IRF_median,VARopt,IRF_lower,IRF_upper);

%%%% HDComp %%%%
% Compute historical decomposition
[HD, VAR] = VARhd(VAR,VARopt);
% Plot historical decomposition
VARhdplot(HD,VARopt);
%BarPlot(HD);


%%%% FEVD %%%%
% Compute forecast error variance decomposition
[VD, VAR] = VARvd(VAR,VARopt);
% Compute confidence interval via bootstrap
[VDinf,VDsup,VDmed,VDbar] = VARvdband(VAR,VARopt);
% Plot
VARvdplot(VDbar,VARopt);
