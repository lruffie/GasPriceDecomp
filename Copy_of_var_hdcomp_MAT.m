%%%% DATA LOADING %%%%
data = readtable("export_normal_data.xlsx");

%%%% DATA CLEANING %%%%

% Choose detrending option: 'log-linear' or 'HP filtering'
%detrend_opt = 'HP filtering';
%switch detrend_opt
%    case 'log-linear'
%        Y = detrend(100.*log(XXX));
%    case 'HP filtering'
%        [~,Y] = hpfilter(100.*log(XXX),1600);
%end

price_gas = data.price_gas;
brent_usd = data.price_brent_usd;
%brent_gbp = data.price_brent_gbp;
OI = data.open_interest_gas;
temp = data.temperature;
lng = data.lng;
storage = data.storage;
euas = data.euas;
supply = data.supply;

X= [price_gas brent_usd OI temp lng storage supply];

%data.months=[];
%data.demand=[];

% Select 'true' or 'false' if you want to plot data
plot_data = true;
if plot_data
    plot(data.Variables);
    legend(data.Properties.VariableNames);
end

%%%% LIB IMPORTS %%%%
% Add VAR toolbox to the MATLAB path (including all subfolders)
%folder = fileparts(which('VAR-Toolbox-main')); 

addpath(genpath('VAR_toolbox'));

% OR USE DYNARE ??


%%%% VAR USE %%%%
% Choose constant and trend
const_trend = 2;
% Choose number of lags
nbr_lags = 4;

% Estimate the VAR
[VAR, VAR_options] = VARmodel(X,nbr_lags,const_trend);
% Show estimated model parameters
VAR_options.vnames = data.Properties.VariableNames;
%VARprint(VAR,VAR_options);


%%%% STRUCTURAL VAR %%%%
% Choose the identification scheme
VAR_options.ident = 'oir';          % 'oir' selects a recursive scheme, (LOOK FOR OTHER SCHEMES)
% Choose the horizon for the impulse responses
VAR_options.nsteps = 24;
% Apply the identification scheme and compute impulse responses
[IRF,VAR] = VARir(VAR,VAR_options);

%%%% IRF %%%%
% Compute confidence intervals using bootstrap methods
[IRF_lower,IRF_upper,IRF_median] = VARirband(VAR,VAR_options);
% Figures related options
VAR_options.savefigs = false;
VAR_options.quality  = 0;
% Plot impulse response functions
VARirplot(IRF_median,VAR_options,IRF_lower,IRF_upper);

%%%% HDComp %%%%
% Compute historical decomposition
HistDecomp = VARhd(VAR);
% Plot historical decomposition
VARhdplot(HistDecomp,VAR_options);


%%%% FEVD %%%%
% Compute forecast error variance decomposition
[FEVD,VAR] = VARfevd(VAR,VAR_options);
% Compute confidence interval via bootstrap
[FEVDINF,FEVDSUP,FEVDMED] = VARfevdband(VAR,VAR_options);

% Plot
VARfevdplot(FEVDMED,VAR_options,FEVDINF,FEVDSUP);