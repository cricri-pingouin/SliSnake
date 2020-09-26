unit SNAKE;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, ExtCtrls,
  Menus, IniFiles, MMSystem; //MMsystem for joystick

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    mniGame: TMenuItem;
    mniNew: TMenuItem;
    mniN3: TMenuItem; //Separator
    mniExit: TMenuItem;
    mniHighscores: TMenuItem;
    mniOptions: TMenuItem;
    mniScore: TMenuItem;
    mniPause: TMenuItem;
    imgBlank: TImage;
    imgBodyHorz: TImage;
    imgBodyVert: TImage;
    imgCornerBL: TImage;
    imgCornerBR: TImage;
    imgCornerTL: TImage;
    imgCornerTR: TImage;
    imgHeadDown: TImage;
    imgHeadLeft: TImage;
    imgHeadRight: TImage;
    imgHeadUp: TImage;
    imgTailDown: TImage;
    imgTailLeft: TImage;
    imgTailRight: TImage;
    imgTailUp: TImage;
    mniAbort: TMenuItem;
    imgFruit1: TImage;
    imgFruit2: TImage;
    imgFruit3: TImage;
    imgFruit4: TImage;
    imgFruit5: TImage;
    imgFruit6: TImage;
    imgFruit7: TImage;
    mniSettings: TMenuItem;
    mniKeys: TMenuItem;
    imgFruit8: TImage;
    imgDownX: TImage;
    imgLeftX: TImage;
    imgRightX: TImage;
    imgUpX: TImage;
    procedure FormCreate(Sender: TObject);
    procedure DrawSnake(X, Y, Shape: Integer);
    procedure DrawFruit(X, Y, Fruit: Integer);
    procedure DrawWholeSnake(IsDead: Boolean);
    procedure NewGame;
    procedure EndGame;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure mniNewClick(Sender: TObject);
    procedure mniPauseClick(Sender: TObject);
    procedure mniAbortClick(Sender: TObject);
    procedure mniExitClick(Sender: TObject);
    procedure mniHighscoresClick(Sender: TObject);
    procedure mniSettingsClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure mniKeysClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    //Settings
    BoardSizeX, BoardSizeY, GameSpeed: Integer;
    //High scores
    HSname: array[1..10] of string;
    HSscore: array[1..10] of DWORD;
  end;

const
  ShapeSize = 32; //Size of a block in pixels

type
  Coord = record
    X: Byte;
    Y: Byte;
  end;

var
  Form1: TForm1;
  //Snake
  SnakeImg: array[0..18] of^TBitmap;
  FruitImg: array[0..7] of^TBitmap;
  SnakePos: array[0..255] of Coord;
  DirectionX, DirectionY: ShortInt;
  SnakeLength: Byte;
  //Fruit
  FruitPos: Coord;
  //Scoring
  Score: DWord;
  Paused, GameEnd: Boolean;
  MyJoy: TJoyInfo;
  ErrorResult: MMRESULT;

implementation

{$R *.dfm}

uses
  OPTIONS, HIGHSCORES;

procedure TForm1.DrawSnake(X, Y, Shape: Integer);
begin
  Form1.Canvas.Draw((X - 1) * ShapeSize, (Y - 1) * ShapeSize, SnakeImg[Shape]^);
end;

procedure TForm1.DrawFruit(X, Y, Fruit: Integer);
begin
  Form1.Canvas.Draw((X - 1) * ShapeSize, (Y - 1) * ShapeSize, FruitImg[Fruit]^);
end;

procedure TForm1.DrawWholeSnake(IsDead: Boolean);
var
  i, DeadOffset: Byte;
begin
  //Draw snake head; 7 down, 8 left, 9 right, 10 up
  if IsDead then
    DeadOffset := 8 //ok so I implemented that later and couldn't bother renumbering all sprites!
  else
    DeadOffset := 0;
  if (DirectionY = 1) then
    DrawSnake(SnakePos[0].X, SnakePos[0].Y, 7 + DeadOffset)
  else if (DirectionX = -1) then
    DrawSnake(SnakePos[0].X, SnakePos[0].Y, 8 + DeadOffset)
  else if (DirectionX = 1) then
    DrawSnake(SnakePos[0].X, SnakePos[0].Y, 9 + DeadOffset)
  else if (DirectionY = -1) then
    DrawSnake(SnakePos[0].X, SnakePos[0].Y, 10 + DeadOffset);
  //Draw snake body; 1 horiz, 2 vert, 3 BL, 4 BR, 5 TL, 6 TR
  for i := 1 to SnakeLength - 1 do
  begin
    if (SnakePos[i].Y = SnakePos[i - 1].Y) and (SnakePos[i].Y = SnakePos[i + 1].Y) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 1) //horizontal
    else if (SnakePos[i].X = SnakePos[i - 1].X) and (SnakePos[i].X = SnakePos[i + 1].X) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 2) //vertical
    else if (SnakePos[i].X = SnakePos[i - 1].X) and (SnakePos[i].Y > SnakePos[i - 1].Y) and (SnakePos[i].X < SnakePos[i + 1].X) and (SnakePos[i].Y = SnakePos[i + 1].Y) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 3) //BL CW
    else if (SnakePos[i].X < SnakePos[i - 1].X) and (SnakePos[i].Y = SnakePos[i - 1].Y) and (SnakePos[i].X = SnakePos[i + 1].X) and (SnakePos[i].Y > SnakePos[i + 1].Y) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 3) //BL CCW
    else if (SnakePos[i].X > SnakePos[i - 1].X) and (SnakePos[i].Y = SnakePos[i - 1].Y) and (SnakePos[i].X = SnakePos[i + 1].X) and (SnakePos[i].Y > SnakePos[i + 1].Y) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 4) //BR CW
    else if (SnakePos[i].X = SnakePos[i - 1].X) and (SnakePos[i].Y > SnakePos[i - 1].Y) and (SnakePos[i].X > SnakePos[i + 1].X) and (SnakePos[i].Y = SnakePos[i + 1].Y) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 4) //BR CCW
    else if (SnakePos[i].X < SnakePos[i - 1].X) and (SnakePos[i].Y = SnakePos[i - 1].Y) and (SnakePos[i].X = SnakePos[i + 1].X) and (SnakePos[i].Y < SnakePos[i + 1].Y) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 5) //TL CW
    else if (SnakePos[i].X = SnakePos[i - 1].X) and (SnakePos[i].Y < SnakePos[i - 1].Y) and (SnakePos[i].X < SnakePos[i + 1].X) and (SnakePos[i].Y = SnakePos[i + 1].Y) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 5) //TL CCW
    else if (SnakePos[i].X = SnakePos[i - 1].X) and (SnakePos[i].Y < SnakePos[i - 1].Y) and (SnakePos[i].X > SnakePos[i + 1].X) and (SnakePos[i].Y = SnakePos[i + 1].Y) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 6) //TR CW
    else if (SnakePos[i].X > SnakePos[i - 1].X) and (SnakePos[i].Y = SnakePos[i - 1].Y) and (SnakePos[i].X = SnakePos[i + 1].X) and (SnakePos[i].Y < SnakePos[i + 1].Y) then
      DrawSnake(SnakePos[i].X, SnakePos[i].Y, 6) //TR CCW
  end;
  //Draw tail; 11 down, 12 left, 13 right, 14 up
  if (SnakePos[SnakeLength].Y < SnakePos[SnakeLength - 1].Y) then
    DrawSnake(SnakePos[SnakeLength].X, SnakePos[SnakeLength].Y, 11)
  else if (SnakePos[SnakeLength].X > SnakePos[SnakeLength - 1].X) then
    DrawSnake(SnakePos[SnakeLength].X, SnakePos[SnakeLength].Y, 12)
  else if (SnakePos[SnakeLength].X < SnakePos[SnakeLength - 1].X) then
    DrawSnake(SnakePos[SnakeLength].X, SnakePos[SnakeLength].Y, 13)
  else if (SnakePos[SnakeLength].Y > SnakePos[SnakeLength - 1].Y) then
    DrawSnake(SnakePos[SnakeLength].X, SnakePos[SnakeLength].Y, 14);
end;

procedure TForm1.NewGame;
var
  i, FruitIndex: Byte;
  CurrTick, PrevTick, LevelTime: DWORD;
  FoodPosOk: Boolean;
  NewHead, OldTail: Coord;
begin
  //Update menu, including score
  mniNew.Enabled := False;
  mniPause.Enabled := True;
  mniAbort.Enabled := True;
  Score := 0;
  mniScore.Caption := 'Score = 0';
  //Set board
  Form1.ClientWidth := BoardSizeX * ShapeSize;
  Form1.ClientHeight := BoardSizeY * ShapeSize;
  Form1.Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
  //Set flags
  GameEnd := False;
  Paused := False;
  //Initialise snake head, body and tail respectively
  SnakeLength := 2;
  SnakePos[0].X := BoardSizeX div 2 + 1;
  SnakePos[0].Y := BoardSizeY div 2;
  SnakePos[1].X := BoardSizeX div 2;
  SnakePos[1].Y := BoardSizeY div 2;
  SnakePos[2].X := BoardSizeX div 2 - 1;
  SnakePos[2].Y := BoardSizeY div 2;
  DirectionX := 1;
  DirectionY := 0;
  //Set fruit
  Randomize;
  repeat
    begin
      FoodPosOk := True;
      FruitPos.X := Random(BoardSizeX) + 1;
      FruitPos.Y := Random(BoardSizeY) + 1;
      for i := 0 to SnakeLength do
        if (FruitPos.X = SnakePos[i].X) and (FruitPos.Y = SnakePos[i].Y) then
        begin
          FoodPosOk := False;
          break;
        end;
    end;
  until FoodPosOk;
  FruitIndex := 0;
  DrawFruit(FruitPos.X, FruitPos.Y, FruitIndex);
  //Initialise timer
  LevelTime := (11 - GameSpeed) * 40;
  PrevTick := GetTickCount();
  repeat
    begin
      CurrTick := GetTickCount();
      //Check joystick
      ErrorResult := joyGetPos(joystickid1, @MyJoy);
      if ErrorResult = JOYERR_NOERROR then
      begin
        //pos varies from 0 to 2^16=65535, so test for 1/4 and 3/4 of max values
        if (DirectionX = 0) and (MyJoy.wXpos < 16384) then
        begin
          //Left
          DirectionX := -1;
          DirectionY := 0;
        end;
        if (DirectionX = 0) and (MyJoy.wXpos > 49152) then
        begin
          //Right
          DirectionX := 1;
          DirectionY := 0;
        end;
        if (DirectionY = 0) and (MyJoy.wYpos < 16384) then
        begin
          //Up
          DirectionX := 0;
          DirectionY := -1;
        end;
        if (DirectionY = 0) and (MyJoy.wYpos > 49152) then
        begin
          //Down
          DirectionX := 0;
          DirectionY := 1;
        end;
      end;
      if ((CurrTick - PrevTick) >= LevelTime) and not Paused then
      begin
        PrevTick := CurrTick;
        //Calculate head position for next move
        NewHead.X := SnakePos[0].X + DirectionX;
        NewHead.Y := SnakePos[0].Y + DirectionY;
        //Hit a wall?
        if (NewHead.X < 1) or (NewHead.X > BoardSizeX) or (NewHead.Y < 1) or (NewHead.Y > BoardSizeY) then
          GameEnd := True;
        //Bit tail?
        for i := 1 to SnakeLength - 1 do //-1 because our snake will move one step so head can be where tail was, and fruit can't possibly be there
          if (NewHead.X = SnakePos[i].X) and (NewHead.Y = SnakePos[i].Y) then
          begin
            GameEnd := True;
            break;
          end;
        //Game end: draw snake with x_x head
        if GameEnd then
          DrawWholeSnake(true)
        else
        begin
          //Update snake coordinates
          OldTail := SnakePos[SnakeLength];
          for i := SnakeLength downto 1 do
          begin
            SnakePos[i].X := SnakePos[i - 1].X;
            SnakePos[i].Y := SnakePos[i - 1].Y;
          end;
          //Update head position
          SnakePos[0].X := NewHead.X;
          SnakePos[0].Y := NewHead.Y;
          //Did snake eat fruit?
          FoodPosOk := False; //Also use it as fruit eaten flag
          if (NewHead.X = FruitPos.X) and (NewHead.Y = FruitPos.Y) then
          begin
            //Score
            Inc(Score, 10 * (SnakeLength - 1));
            mniScore.Caption := 'Score = ' + IntToStr(Score);
            //Extend snake here
            Inc(SnakeLength);
            SnakePos[SnakeLength].X := OldTail.X;
            SnakePos[SnakeLength].Y := OldTail.Y;
           //Set new food position
            repeat
              begin
                FoodPosOk := True;
                FruitPos.X := Random(BoardSizeX) + 1;
                FruitPos.Y := Random(BoardSizeY) + 1;
                for i := 0 to SnakeLength do
                  if (FruitPos.X = SnakePos[i].X) and (FruitPos.Y = SnakePos[i].Y) then
                  begin
                    FoodPosOk := False;
                    break;
                  end;
              end;
            until FoodPosOk;
            Inc(FruitIndex);
            if (FruitIndex = 8) then
              FruitIndex := 0;
            DrawFruit(FruitPos.X, FruitPos.Y, FruitIndex);
          end;
          //Draw snake with normal head
          DrawWholeSnake(false);
          //Snake didn't eat fruit (FoodPosOk=False) and head not on old tail: blank old tail end
          if (FoodPosOk = False) and not ((NewHead.X = OldTail.X) and (NewHead.Y = OldTail.Y)) then
            DrawSnake(OldTail.X, OldTail.Y, 0);
        end;
      end
      else
      begin
        Application.ProcessMessages;
        Sleep(15);
      end;
    end;
  until GameEnd or (Application.Terminated);
  EndGame();
  //Update menu
  mniNew.Enabled := True;
  mniPause.Enabled := False;
  mniAbort.Enabled := False;
end;

procedure TForm1.EndGame;
var
  X, Y: Byte;
  myINI: TINIFile;
  //High score
  WinnerName: string;
begin
  //Highscore?
  for X := 1 to 10 do
  begin
    if (Score > HSscore[X]) then
    begin
      //Get name
      WinnerName := InputBox('You''re Winner!', 'You placed #' + IntToStr(X) + ' with your score of ' + IntToStr(Score) + '.' + slinebreak + 'Enter your name:', HSname[1]);
      //Shift high scores downwards; If placed 10, skip as we'll simply overwrite last score
      if X < 10 then
        for Y := 10 downto X + 1 do
        begin
          HSname[Y] := HSname[Y - 1];
          HSscore[Y] := HSscore[Y - 1];
        end;
      //Set new high score
      HSname[X] := WinnerName;
      HSscore[X] := Score;
      //Save high scores to INI file
      myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliSnake.ini');
      for Y := 1 to 10 do
      begin
        myINI.WriteString('HighScores', 'Name' + IntToStr(Y), HSname[Y]);
        myINI.WriteInteger('HighScores', 'Score' + IntToStr(Y), HSscore[Y]);
      end;
      //Close INI file
      myINI.Free;
      //Exit so that we only get 1 high score!
      Exit;
    end;
  end;
  ShowMessage('Game over and your score of ' + IntToStr(Score) + ' is not a high score.');
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  myINI: TINIFile;
  i: Byte;
begin
  //Initialise options from INI file
  myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliSnake.ini');
  BoardSizeX := myINI.ReadInteger('Settings', 'BoardSizeX', 25);
  BoardSizeY := myINI.ReadInteger('Settings', 'BoardSizeY', 15);
  GameSpeed := myINI.ReadInteger('Settings', 'Speed', 7);
  //Read high scores from INI file
  for i := 1 to 10 do
  begin
    HSname[i] := myINI.ReadString('HighScores', 'Name' + IntToStr(i), 'Nobody');
    HSscore[i] := myINI.ReadInteger('HighScores', 'Score' + IntToStr(i), (11 - i) * 100);
  end;
  myINI.Free;
  //Initialise shapes images
  //Snake body
  New(SnakeImg[0]);
  SnakeImg[0]^ := imgBlank.Picture.Bitmap;
  New(SnakeImg[1]);
  SnakeImg[1]^ := imgBodyHorz.Picture.Bitmap;
  New(SnakeImg[2]);
  SnakeImg[2]^ := imgBodyVert.Picture.Bitmap;
  New(SnakeImg[3]);
  SnakeImg[3]^ := imgCornerBL.Picture.Bitmap;
  New(SnakeImg[4]);
  SnakeImg[4]^ := imgCornerBR.Picture.Bitmap;
  New(SnakeImg[5]);
  SnakeImg[5]^ := imgCornerTL.Picture.Bitmap;
  New(SnakeImg[6]);
  SnakeImg[6]^ := imgCornerTR.Picture.Bitmap;
  //Snake head
  New(SnakeImg[7]);
  SnakeImg[7]^ := imgHeadDown.Picture.Bitmap;
  New(SnakeImg[8]);
  SnakeImg[8]^ := imgHeadLeft.Picture.Bitmap;
  New(SnakeImg[9]);
  SnakeImg[9]^ := imgHeadRight.Picture.Bitmap;
  New(SnakeImg[10]);
  SnakeImg[10]^ := imgHeadUp.Picture.Bitmap;
  //Snake tail
  New(SnakeImg[11]);
  SnakeImg[11]^ := imgTailDown.Picture.Bitmap;
  New(SnakeImg[12]);
  SnakeImg[12]^ := imgTailLeft.Picture.Bitmap;
  New(SnakeImg[13]);
  SnakeImg[13]^ := imgTailRight.Picture.Bitmap;
  New(SnakeImg[14]);
  SnakeImg[14]^ := imgTailUp.Picture.Bitmap;
  //Snake dead head
  New(SnakeImg[15]);
  SnakeImg[15]^ := imgDownX.Picture.Bitmap;
  New(SnakeImg[16]);
  SnakeImg[16]^ := imgLeftX.Picture.Bitmap;
  New(SnakeImg[17]);
  SnakeImg[17]^ := imgRightX.Picture.Bitmap;
  New(SnakeImg[18]);
  SnakeImg[18]^ := imgUpX.Picture.Bitmap;
  //Fruits
  New(FruitImg[0]);
  FruitImg[0]^ := imgFruit1.Picture.Bitmap;
  New(FruitImg[1]);
  FruitImg[1]^ := imgFruit2.Picture.Bitmap;
  New(FruitImg[2]);
  FruitImg[2]^ := imgFruit3.Picture.Bitmap;
  New(FruitImg[3]);
  FruitImg[3]^ := imgFruit4.Picture.Bitmap;
  New(FruitImg[4]);
  FruitImg[4]^ := imgFruit5.Picture.Bitmap;
  New(FruitImg[5]);
  FruitImg[5]^ := imgFruit6.Picture.Bitmap;
  New(FruitImg[6]);
  FruitImg[6]^ := imgFruit7.Picture.Bitmap;
  New(FruitImg[7]);
  FruitImg[7]^ := imgFruit8.Picture.Bitmap;
  //Initialise flags
  GameEnd := False;
  Paused := False;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TForm1.mniNewClick(Sender: TObject);
begin
  NewGame();
end;

procedure TForm1.mniPauseClick(Sender: TObject);
begin
  Paused := not Paused;
end;

procedure TForm1.mniAbortClick(Sender: TObject);
begin
  GameEnd := True;
end;

procedure TForm1.mniExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.mniHighscoresClick(Sender: TObject);
begin
  if Form3.Visible = False then
    Form3.Show
  else
    Form3.Hide;
end;

procedure TForm1.mniKeysClick(Sender: TObject);
begin
  ShowMessage('Left:' + #9 + #9 + 'Left or numpad 4 or joystick left' + sLineBreak + 'Right:' + #9 + #9 + 'Right or numpad 6 or joystick right' + sLineBreak + 'Down:' + #9 + #9 + 'Down or numpad 2 or joystick down' + sLineBreak + 'Up:' + #9 + #9 + 'Up or numpad 8 or joystick up' + sLineBreak + 'Start new game:' + #9 + 'Space' + sLineBreak + 'Pause:' + #9 + #9 + 'Pause' + sLineBreak + 'End game:' + #9 + 'Esc');
end;

procedure TForm1.mniSettingsClick(Sender: TObject);
begin
  if Form2.Visible = False then
    Form2.Show
  else
    Form2.Hide;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if GameEnd then
    if (Key = 32) then //Game over and space: start new game
      NewGame()
    else
      Exit; //Else ignore all key presses
  if Paused then
  begin
    if (Key = 19) then  //Paused and press Pause: unpause
      Paused := False;
    Exit;
  end;
  case Key of
    37, 100: //Left or num 4
      if DirectionX = 0 then
      begin
        DirectionX := -1;
        DirectionY := 0;
      end;
    38, 104: //Up (Up or num 8)
      if DirectionY = 0 then
      begin
        DirectionX := 0;
        DirectionY := -1;
      end;
    39, 102: //Right or num 6
      if DirectionX = 0 then
      begin
        DirectionX := 1;
        DirectionY := 0;
      end;
    40, 98: //Down or num 2
      if DirectionY = 0 then
      begin
        DirectionX := 0;
        DirectionY := 1;
      end;
    27: //Escape
      GameEnd := True;
    19: //Pause
      Paused := True;
  end;
end;

end.

