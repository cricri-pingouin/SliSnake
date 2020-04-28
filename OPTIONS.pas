unit OPTIONS;

interface

uses
  SysUtils, Classes, Controls, Forms,
  StdCtrls, SNAKE, IniFiles;

type
  tForm2 = class(TForm)
    lblX: TLabel;
    scrlX: TScrollBar;
    lblY: TLabel;
    scrlY: TScrollBar;
    btnCancel: TButton;
    btnOk: TButton;
    lblXval: TLabel;
    lblYval: TLabel;
    scrlSpeed: TScrollBar;
    lblSpeed: TLabel;
    lblSpeedVal: TLabel;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure scrlXChange(Sender: TObject);
    procedure scrlYChange(Sender: TObject);
    procedure scrlSpeedChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: tForm2;

implementation

{$R *.dfm}

procedure tForm2.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure tForm2.btnOkClick(Sender: TObject);
var
  myINI: TINIFile;
begin
  Form1.BoardSizeX := scrlX.Position;
  Form1.BoardSizeY := scrlY.Position;
  Form1.GameSpeed := scrlSpeed.Position;
   //Save settings to INI file
  myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliSnake.ini');
  myINI.WriteInteger('Settings', 'BoardSizeX', Form1.BoardSizeX);
  myINI.WriteInteger('Settings', 'BoardSizeY', Form1.BoardSizeY);
  myINI.WriteInteger('Settings', 'Speed', Form1.GameSpeed);
  myINI.Free;
  Close;
end;

procedure tForm2.FormCreate(Sender: TObject);
begin
  scrlX.Position := Form1.BoardSizeX;
  lblXval.Caption := IntToStr(scrlX.Position);
  scrlY.Position := Form1.BoardSizeY;
  lblYval.Caption := IntToStr(scrlY.Position);
  scrlSpeed.Position := Form1.GameSpeed;
  lblSpeedVal.Caption := IntToStr(scrlSpeed.Position);
end;

procedure tForm2.scrlXChange(Sender: TObject);
begin
  lblXval.Caption := IntToStr(scrlX.Position);
end;

procedure tForm2.scrlYChange(Sender: TObject);
begin
  lblYval.Caption := IntToStr(scrlY.Position);
end;

procedure tForm2.scrlSpeedChange(Sender: TObject);
begin
  lblSpeedVal.Caption := IntToStr(scrlSpeed.Position);
end;

end.
