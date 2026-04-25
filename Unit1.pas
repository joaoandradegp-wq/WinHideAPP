unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RXShell, StdCtrls, ComCtrls, GraphicEx, ExtCtrls, ShellAPI, jpeg;

const
  HOTKEY_ID = 1;

type
  THiddenItem = record
    Handle: HWND;
    ExStyle: Longint;
  end;

type
  TForm1 = class(TForm)
    RxTrayIcon1: TRxTrayIcon;
    Label1: TLabel;
    StatusBar1: TStatusBar;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure RxTrayIcon1DblClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
  private
    HiddenList: array of THiddenItem; // ? AGORA AQUI
    procedure WMHotKey(var Msg: TMessage); message WM_HOTKEY;

    procedure HideWindow(h: HWND);      // ? vira método
    procedure RestoreAllWindows;        // ? vira método
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.HideWindow(h: HWND);
var
item: THiddenItem;
i: Integer;
begin

  {EVITA DUPLICAR}
  for i := 0 to High(HiddenList) do

    if HiddenList[i].Handle = h then
    Exit;

  item.Handle := h;
  item.ExStyle := GetWindowLong(h, GWL_EXSTYLE);
  SetLength(HiddenList, Length(HiddenList) + 1);
  HiddenList[High(HiddenList)] := item;
  SetWindowLong(h, GWL_EXSTYLE, item.ExStyle or WS_EX_TOOLWINDOW);
  SetWindowPos(h, 0, 0,0,0,0,
  SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
  ShowWindow(h, SW_HIDE);

end;

procedure TForm1.RestoreAllWindows;
var
i: Integer;
begin

  for i := 0 to High(HiddenList) do
  begin
  SetWindowLong(HiddenList[i].Handle, GWL_EXSTYLE, HiddenList[i].ExStyle);
  SetWindowPos(HiddenList[i].Handle, 0, 0,0,0,0,
  SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
  ShowWindow(HiddenList[i].Handle, SW_SHOW);
  ShowWindow(HiddenList[i].Handle, SW_RESTORE);
  end;
SetLength(HiddenList, 0);

end;

procedure TForm1.WMHotKey(var Msg: TMessage);
var
h: HWND;
begin

  if Msg.WParam = HOTKEY_ID then
  begin
    if GetAsyncKeyState(VK_SHIFT) <> 0 then
    begin
    RestoreAllWindows;
    Exit;
    end;
  h:=GetForegroundWindow;
    if (h <> 0) and (h <> Handle) then
    HideWindow(h);
  end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
//------------------------------------------------------------------
{INICIA COMO TRAYICON}
//------------------------------------------------------------------
SetLength(HiddenList, 0);
RegisterHotKey(Handle, HOTKEY_ID, MOD_CONTROL or MOD_ALT, Ord('H'));
RxTrayIcon1.Active := True;
Application.ShowMainForm := False;
Hide;
//------------------------------------------------------------------
SetLength(HiddenList, 0);
RegisterHotKey(Handle, HOTKEY_ID, MOD_CONTROL or MOD_ALT, Ord('H'));
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
UnregisterHotKey(Handle, HOTKEY_ID);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
RestoreAllWindows;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
Form1.Caption:=Application.Title;
end;

procedure TForm1.RxTrayIcon1DblClick(Sender: TObject);
begin

  if Self.Visible then
  Hide
  else
  begin
  Show;
  WindowState:=wsNormal;
  SetForegroundWindow(Handle);
  end;

end;

procedure TForm1.Image1Click(Sender: TObject);
begin
Hide;
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
ShellExecute(0, 'open', 'https://phobosfreeware.blogspot.com', nil, nil, SW_SHOWNORMAL);
end;

end.
