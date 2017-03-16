function varargout = TestBerg(varargin)
% TESTBERG MATLAB code for TestBerg.fig
%      TESTBERG, by itself, creates a new TESTBERG or raises the existing
%      singleton*.
%
%      H = TESTBERG returns the handle to a new TESTBERG or t/he handle to
%      the existing singleton*.
%
%      TESTBERG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TESTBERG.M with the given input arguments.
%
%      TESTBERG('Property','Value',...) creates a new TESTBERG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TestBerg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TestBerg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TestBerg

% Last Modified by GUIDE v2.5 22-Apr-2016 08:49:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TestBerg_OpeningFcn, ...
                   'gui_OutputFcn',  @TestBerg_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before TestBerg is made visible.
function TestBerg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TestBerg (see VARARGIN)

% Choose default command line output for TestBerg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TestBerg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TestBerg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pbChoose.
function pbChoose_Callback(hObject, eventdata, handles)
% hObject    handle to pbChoose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
[filename, pathname] = uigetfile('*.*','Wybierz plik');
FullPathName = strcat(pathname,filename);
set(handles.path,'String',FullPathName);
catch
end

% --- Executes on button press in pbRead.
function pbRead_Callback(hObject, eventdata, handles)
% hObject    handle to pbRead (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
path = get(handles.path, 'String');

movie = VideoReader(path);
movWidth = movie.Width;
movHeight = movie.Height;

mov = read(movie);

first = mov(:,:,:,1);
last = mov(:,:,:,end);

if(movWidth > movHeight)
    first = imrotate(first,90);
    last = imrotate(last,90);
end

assignin('base','first',first);
assignin('base','last',last);

axes(handles.axBefore);
imshow(first);
hold on;
axes(handles.axAfter);
imshow(last);
hold on;

% --- Executes on button press in pbResult.
function pbResult_Callback(hObject, eventdata, handles)
% hObject    handle to pbResult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
first = evalin('base','first');
last = evalin('base','last');

hgamma = vision.GammaCorrector(2,'Correction','De-gamma');

gamma1 = step(hgamma, first);
gray1 = (gamma1(:,:,1) + gamma1(:,:,2) + gamma1(:,:,3)) / 3;
gray1 = medfilt2(gray1);

gamma2 = step(hgamma, last);
gray2 = (gamma2(:,:,1) + gamma2(:,:,2) + gamma2(:,:,3)) / 3;
gray2 = medfilt2(gray2);

r = 5;
l = 50;

[w1,k1] = size(gray1);
gray_min1 = min(min(gray1));
gray_max1 = max(max(gray1));

Jw1 = zeros(w1,k1);
MAX1=ordfilt2(gray1,r*r,ones(r),'symmetric');
MIN1=ordfilt2(gray1,1,ones(r),'symmetric');
t1=0.3*MAX1+0.7*MIN1;
C1=MAX1-MIN1;
tOtsu1=(gray_max1-gray_min1)*graythresh(gray1);

Jw1(gray1<t1)=1;
Jw1(C1<l & gray1>=tOtsu1)=0;

Jw_first =(1-Jw1);
Jw_first = medfilt2(Jw_first);

[w2,k2] = size(gray2);
gray_min2 = min(min(gray2));
gray_max2 = max(max(gray2));

Jw2 = zeros(w2,k2);
MAX2=ordfilt2(gray2,r*r,ones(r),'symmetric');
MIN2=ordfilt2(gray2,1,ones(r),'symmetric');
t2=0.3*MAX2+0.7*MIN2;
C2=MAX2-MIN2;
tOtsu2=(gray_max2-gray_min2)*graythresh(gray2);

Jw2(gray2<t2)=1;
Jw2(C2<l & gray2>=tOtsu2)=0;

Jw_last =(1-Jw2);
Jw_last = medfilt2(Jw_last);

reg_first = regionprops(Jw_first);
[MAP_first, liczbaregionow_first] = bwlabel(Jw_first);
WL_first = regionprops(MAP_first, {'Area', 'Centroid','Extent'});
Area_first = cell2mat({WL_first.Area});
Extent_first = cell2mat({WL_first.Extent});

Rc1_first = 2 * sqrt(Area_first ./ pi);
ind_first = find(Rc1_first> 6.5 & Rc1_first < 8 & Extent_first > 0.82 & Extent_first < 0.92);
pierwszy_first = WL_first(ind_first(1)).Centroid;
drugi_first = WL_first(ind_first(2)).Centroid;

reg_last = regionprops(Jw_last);
[MAP_last, liczbaregionow_last] = bwlabel(Jw_last);
WL_last = regionprops(MAP_last, {'Area', 'Centroid','Extent'});
Area_last = cell2mat({WL_last.Area});
Extent_last = cell2mat({WL_last.Extent});

Rc1_last = 2 * sqrt(Area_last ./ pi);
ind_last = find(Rc1_last > 6.5 & Rc1_last < 8 & Extent_last > 0.75 & Extent_last < 0.91);
pierwszy_last = WL_last(ind_last(1)).Centroid;
drugi_last = WL_last(ind_last(2)).Centroid;

x1_first=pierwszy_first(1);
x2_first=drugi_first(1);
y1_first=pierwszy_first(2);
y2_first= drugi_first(2);

x1_last=pierwszy_last(1);
x2_last=drugi_last(1);
y1_last=pierwszy_last(2);
y2_last=drugi_last(2);

axes(handles.axBefore);
plot([x1_first x2_first],[y1_first y2_first], 'r*');

axes(handles.axAfter);
plot([x1_last x2_last],[y1_last y2_last], 'r*');

odleglosc_first = sqrt((x2_first-x1_first)^2 + (y2_first-y1_first)^2);
odleglosc_last = sqrt((x2_last-x1_last)^2 + (y2_last-y1_last)^2);

zmiana_pion = (y1_last - y2_last) / (y1_first - y2_first);
zmiana_poziom= (x1_last - x2_last) / (x1_first - x2_first);

glebokosc_sklonu = 0.8* zmiana_pion + 0.2*zmiana_poziom;

if(glebokosc_sklonu < 0.2)
    ocena = 4;
elseif(glebokosc_sklonu >= 0.2 && glebokosc_sklonu < 0.4)
    ocena = 3;
elseif(glebokosc_sklonu >= 0.4 && glebokosc_sklonu < 0.6)
    ocena = 2;
elseif(slebokosc_sklonu >= 0.6 && glebokosc_sklonu < 0.8)
    ocena = 1;
else
    ocena = 0;
end

komunikat = strcat('Twój wynik to: ', num2str(ocena));
assignin('base','komunikat',komunikat);
result
