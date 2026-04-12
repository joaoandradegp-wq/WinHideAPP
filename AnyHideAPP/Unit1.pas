unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RXShell, StdCtrls, ComCtrls, GraphicEx, ExtCtrls, ShellAPI,
  TlHelp32, PsAPI;

const
  HOTKEY_ID = 1;
   SW_FORCEMINIMIZE = 11;

type
  THiddenItem = record
    Handle: HWND;
    ExStyle: Longint;
  end;

type
  TForm1 = class(TForm)
    RxTrayIcon1: TRxTrayIcon;
    StatusBar1: TStatusBar;
    Image1: TImage;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure RxTrayIcon1DblClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    HiddenList: array of THiddenItem;
    procedure WMHotKey(var Msg: TMessage); message WM_HOTKEY;

    procedure HideWindow(h: HWND);
    procedure RestoreAllWindows;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure KillFromTaskbar(h: HWND);
begin
  // remove da barra
  SetWindowLong(h, GWL_EXSTYLE,
    GetWindowLong(h, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);

  // força minimizar (sem fechar sessão)
  ShowWindow(h, SW_FORCEMINIMIZE);

  // tira foco
  ShowWindow(h, SW_HIDE);
end;

function GetClassNameStr(h: HWND): string;
var
  Buf: array[0..255] of Char;
begin
  GetClassName(h, Buf, Length(Buf));
  Result := Buf;
end;

function GetProcessName(h: HWND): string;
var
PID: DWORD;
hProc: THandle;
Buffer: array[0..MAX_PATH] of Char;
begin
Result := '';
GetWindowThreadProcessId(h, @PID);

  hProc := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID);
  if hProc <> 0 then
  begin
    if GetModuleFileNameEx(hProc, 0, Buffer, MAX_PATH) > 0 then
    Result := ExtractFileName(Buffer);

  CloseHandle(hProc);
  end;

end;

procedure RemoveFromTaskbar(h: HWND);
var
  ExStyle: Longint;
begin
  ExStyle := GetWindowLong(h, GWL_EXSTYLE);

  // remove da barra de tarefas
  ExStyle := ExStyle and not WS_EX_APPWINDOW;

  // adiciona como toolwindow
  ExStyle := ExStyle or WS_EX_TOOLWINDOW;

  SetWindowLong(h, GWL_EXSTYLE, ExStyle);

  SetWindowPos(h, 0, 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
end;

function EnumWindowsProc(h: HWND; lParam: LPARAM): BOOL; stdcall;
var
  ProcName: string;
  ClassName: string;
begin
  Result := True;

  ProcName := GetProcessName(h);
  ClassName := LowerCase(GetClassNameStr(h));

  if SameText(ProcName, 'AnyDesk.exe') then
  begin
    if Pos('ad_win', ClassName) > 0 then
    begin
      RemoveFromTaskbar(h);
    end;
  end;
end;

procedure TForm1.HideWindow(h: HWND);
begin
  ShowWindow(h, SW_FORCEMINIMIZE);
end;
              {
procedure TForm1.HideWindow(h: HWND);
var
  item: THiddenItem;
  i: Integer;
begin
  // evita duplicar
  for i := 0 to High(HiddenList) do
    if HiddenList[i].Handle = h then Exit;

  item.Handle := h;
  item.ExStyle := GetWindowLong(h, GWL_EXSTYLE);

  SetLength(HiddenList, Length(HiddenList) + 1);
  HiddenList[High(HiddenList)] := item;

  // ?? remove da taskbar + ALT+TAB
  SetWindowLong(h, GWL_EXSTYLE, item.ExStyle or WS_EX_TOOLWINDOW);

  // ?? move pra fora da tela (FUNCIONA EM QUALQUER CASO)
  SetWindowPos(h, 0, -2000, -2000, 0, 0,
    SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);

  // ?? tenta esconder também (fallback)
  ShowWindow(h, SW_HIDE);
end;           }


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
begin
  if Msg.WParam = HOTKEY_ID then
  begin
    // força minimizar qualquer janela ativa (inclusive AnyDesk)
    keybd_event(VK_MENU, 0, 0, 0);
    keybd_event(VK_SPACE, 0, 0, 0);
    keybd_event(VK_SPACE, 0, KEYEVENTF_KEYUP, 0);

    keybd_event(Ord('N'), 0, 0, 0);
    keybd_event(Ord('N'), 0, KEYEVENTF_KEYUP, 0);

    keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
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

procedure TForm1.Timer1Timer(Sender: TObject);

begin
EnumWindows(@EnumWindowsProc, 0);
end;

end.
