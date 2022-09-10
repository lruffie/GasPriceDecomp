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

%months = data.months;
price_gas = data.price_gas;
brent_gbp = data.price_brent_gbp;
% coal = data.coal_gbp;
% OI = data.open_interest_gas;
% temp = data.temperature;
% temp_dev = data.temp_deviation;
% churn = data.churn;
% EUR = data.eurgbp;
% USD = data.gbpusd;
% lng = data.lng;
% storage = data.storage;
% euas = data.euas;
supply = data.supply;

X= [price_gas brent_gbp supply];

data.months=[];

% Select 'true' or 'false' if you want to plot data
plot_data = true;
if plot_data
    plot(dates,data.Variables);
    legend(data.Properties.VariableNames);
end

%%%% LIB IMPORTS %%%%
% Add VAR toolbox to the MATLAB path (including all subfolders)
%folder = fileparts(which('VAR-Toolbox-main')); 

addpath(genpath('VAR-Toolbox-main'));

% OR USE DYNARE ??


%%%% VAR USE %%%%
% Choose constant and trend
const_trend = 0; %const: 0 no constant; 1 constant; 2 constant and trend; 3 constant and trend^2 [dflt = 0]
% Choose number of lags
nbr_lags = 12;

% Estimate the VAR
[VAR, VAR_options] = VARmodel(X,nbr_lags,const_trend);
% Show estimated model parameters
VAR_options.vnames = data.Properties.VariableNames;
VARprint(VAR,VAR_options);


%%%% STRUCTURAL VAR %%%%
% Choose the identification scheme
VAR_options.ident = 'short'; %'short', 'long', 'iv'  ,'sign'      % 'oir' selects a recursive scheme, (LOOK FOR OTHER SCHEMES)
% Choose the horizon for the impulse responses
VAR_options.nsteps = 36;
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