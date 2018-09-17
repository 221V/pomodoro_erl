-module(pomodoroerl).
-export([start/0]).
-export([handle_click/2, update_gui/4]).

% code:lib_dir(wx)
% /usr/lib/erlang/lib/wx-1.8.4

-include_lib("wx/include/wx.hrl").


start() ->
  wx:new(),
  Frame = wxFrame:new(wx:null(), ?wxID_ANY, "Pomodoro Erl",
    [{style, 
      ?wxMAXIMIZE_BOX bor
      ?wxMINIMIZE_BOX bor
      ?wxRESIZE_BORDER bor
      %%?wxNO_BORDER bor
      %%?wxFRAME_NO_TASKBAR bor
      %?wxUSE_DRAG_AND_DROP bor
      ?wxSTAY_ON_TOP
      }] ),
  
  %Label = wxStaticText:new(Frame, ?wxID_ANY, "Pomodoro Erl"),
  LabelTxt = wxStaticText:new(Frame, ?wxID_ANY, "minutes: Work | Rest time"),
  
  Counter = wxTextCtrl:new(Frame, ?wxID_ANY, [{value, "45|15"}, {size, {190, 50}}, {style, ?wxALIGN_RIGHT}] ),
  Font = wxFont:new(42, ?wxFONTFAMILY_DEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_BOLD),
  wxTextCtrl:setFont(Counter, Font),
  
  %Button = wxButton:new(Frame, ?wxID_ANY, [{label, "Start"}, {style, ?wxBU_RIGHT}] ),
  Button = wxButton:new(Frame, ?wxID_ANY, [{label, "Start"}] ),
  
  MainSizer = wxBoxSizer:new(?wxVERTICAL),
  %wxSizer:add(MainSizer, Label, [{flag, ?wxALL bor ?wxALIGN_CENTRE}, {border, 3}]),
  
  wxSizer:add(MainSizer, LabelTxt, [{flag, ?wxALL bor ?wxEXPAND}, {border, 3}]),
  wxSizer:add(MainSizer, Counter, [{flag, ?wxEXPAND bor ?wxALL}, {border, 3}]),
  wxSizer:add(MainSizer, Button, [{flag, ?wxEXPAND bor ?wxALL}, {border, 3}]),
  
  wxWindow:setSizer(Frame, MainSizer),
  wxSizer:setSizeHints(MainSizer, Frame),
  
  wxButton:connect(Button, command_button_clicked, [{callback, fun handle_click/2}, {userData, #{counter => Counter, label_txt => LabelTxt, env => wx:get_env()}} ] ),
  
  %wx:connect(Frame, ?wxEVT_CLOSE_WINDOW, fun(_,_) -> wx:quit() end),
  
  wxFrame:show(Frame),
  timer:sleep(864000000).


handle_click(#wx{obj = Button, userData = #{counter := Counter, label_txt := LabelTxt, env := Env}}, _Event) ->
  wx:set_env(Env),
  Label = wxButton:getLabel(Button),
  
  case Label of
    "Start" ->
      wxTextCtrl:setEditable(Counter, false),
      wxButton:setLabel(Button, "Stop"),
      wxStaticText:setLabel(LabelTxt, "Work time"),
      
      Counters_Data = wxTextCtrl:getValue(Counter),
      [CounterWork, CounterRest|_] = string:split(Counters_Data, "|"),
      CounterWorkSec = erlang:list_to_integer(CounterWork) * 60,
      CounterRestSec = erlang:list_to_integer(CounterRest) * 60,
      
      play_mp3(),
      
      wxTextCtrl:setValue(Counter, time4list(erlang:list_to_integer(CounterWork)) ++ ":00"),
      StartValues = {CounterWorkSec, CounterRestSec},
      
      timer:apply_after(1000, ?MODULE, update_gui, [{Counter, LabelTxt, StartValues}, Button, Env, {CounterWorkSec - 1, CounterRestSec}]);
    "Stop" ->
      wxTextCtrl:setEditable(Counter, true),
      wxButton:setLabel(Button, "Start"),
      wxStaticText:setLabel(LabelTxt, "minutes: Work | Rest time"),
      wxTextCtrl:setValue(Counter, "45|15")
  end.


update_gui({Counter, LabelTxt, StartValues} = Sys, Button, Env, {CounterWorkSec, CounterRestSec}) ->
  wx:set_env(Env),
  
  Label_Now = wxStaticText:getLabel(LabelTxt),
  Button_Txt = wxButton:getLabel(Button),
  
  case Button_Txt of
    "Stop" ->
      
      if Label_Now =:= "Work time", CounterWorkSec >= 0 ->
          % work time
          MinutesWork = time4list(CounterWorkSec div 60),
          SecondsWork = time4list(CounterWorkSec rem 60),
          
          wxTextCtrl:setValue(Counter, MinutesWork ++ ":" ++ SecondsWork),
          
          timer:apply_after(1000, ?MODULE, update_gui, [Sys, Button, Env, {CounterWorkSec - 1, CounterRestSec}]);
        
        Label_Now =:= "Work time" ->
          % work time ends, begin rest time
          play_mp3(),
          wxStaticText:setLabel(LabelTxt, "Rest time"),
          MinutesRest = time4list(CounterRestSec div 60),
          SecondsRest = time4list(CounterRestSec rem 60),
          
          wxTextCtrl:setValue(Counter, MinutesRest ++ ":" ++ SecondsRest),
          
          timer:apply_after(1000, ?MODULE, update_gui, [Sys, Button, Env, {CounterWorkSec, CounterRestSec - 1}]);
        
        Label_Now =:= "Rest time", CounterRestSec >= 0 ->
          % rest time
          MinutesRest = time4list(CounterRestSec div 60),
          SecondsRest = time4list(CounterRestSec rem 60),
          
          wxTextCtrl:setValue(Counter, MinutesRest ++ ":" ++ SecondsRest),
          
          timer:apply_after(1000, ?MODULE, update_gui, [Sys, Button, Env, {CounterWorkSec, CounterRestSec - 1}]);
        
        Label_Now =:= "Rest time" ->
          % rest time ends, begin work time
          play_mp3(),
          wxStaticText:setLabel(LabelTxt, "Work time"),
          {CounterWorkSec0, CounterRestSec0} = StartValues,
          
          MinutesWork = time4list(CounterWorkSec0 div 60),
          SecondsWork = time4list(CounterWorkSec0 rem 60),
          
          wxTextCtrl:setValue(Counter, MinutesWork ++ ":" ++ SecondsWork),
          
          timer:apply_after(1000, ?MODULE, update_gui, [Sys, Button, Env, {CounterWorkSec0 - 1, CounterRestSec0}])
          
      end;
      
    "Start" ->
      ok
  end.



play_mp3() ->
  erlang:spawn(fun() -> os:cmd("mplayer gong.mp3") end).


time4list(N) when N < 10 ->
  "0" ++ erlang:integer_to_list(N);
time4list(N) ->
  erlang:integer_to_list(N).




