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

function EnumChildProc(h: HWND; lParam: LPARAM): BOOL; stdcall;
begin
  Result := True;

  if IsWindowVisible(h) then
    Form1.HideWindow(h);
end;

function GetAnyDeskPID: DWORD;
var
  Snap: THandle;
  ProcEntry: TProcessEntry32;
begin
  Result := 0;

  Snap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  ProcEntry.dwSize := SizeOf(ProcEntry);

  if Process32First(Snap, ProcEntry) then
  begin
    repeat
      if SameText(ProcEntry.szExeFile, 'AnyDesk.exe') then
      begin
        Result := ProcEntry.th32ProcessID;
        Break;
      end;
    until not Process32Next(Snap, ProcEntry);
  end;

  CloseHandle(Snap);
end;

function GetClassNameStr(h: HWND): string;
var
  Buffer: array[0..255] of Char;
begin
  GetClassName(h, Buffer, 255);
  Result := Buffer;
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

function EnumWindowsProc(h: HWND; lParam: LPARAM): BOOL; stdcall;
var
  PID: DWORD;
begin
  Result := True;

  GetWindowThreadProcessId(h, @PID);

  if PID = lParam then
  begin
    // esconde a janela principal
    if IsWindowVisible(h) then
      Form1.HideWindow(h);

    // ?? AGORA O SEGREDO
    EnumChildWindows(h, @EnumChildProc, 0);
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

procedure TForm1.Timer1Timer(Sender: TObject);
var
  pid: DWORD;
begin
  pid := GetAnyDeskPID;

  if pid <> 0 then
    EnumWindows(@EnumWindowsProc, pid);
end;

end.
