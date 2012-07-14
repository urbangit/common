unit dirstack;

interface

uses SysUtils,Classes;

const
  MAX_DIR_COUNT = 50000;

type
  TDirectoryStack = class;
  TOnDirectoryEvent = procedure (Stack: TDirectoryStack; Dir: string) of object;
  TDirectoryStack = class
  private
    FDirList: TStringList;
    function GetCount: integer;
    function GetItem(Index: integer): string;
    function GetSorted: boolean;
    procedure SetSorted(const Value: boolean);
  public
    function Pop: string;
    function Peek: string;
    procedure Push(Dir: string);
    property Count: integer read GetCount;
    property Items[Index: integer]: string read GetItem; default;
    property Sorted: boolean read GetSorted write SetSorted;
    constructor Create;
    destructor Destroy; override;
  end;

  TDirs = class(TDirectoryStack)
  private
    FRootPath: string;
    FDirDelim: char;
    FMaxDirCount: integer;
    FOnDirectory: TOnDirectoryEvent;
    procedure PopulateDirStack;
    procedure DoOnDirectory(Dir: string);
  public
    property OnDirectory: TOnDirectoryEvent read FOnDirectory write FOnDirectory;
    property DirDelimiter: char read FDirDelim write FDirDelim;
    procedure Populate;
    procedure Enumerate;
    constructor Create(RootPath: string; Max: integer = MAX_DIR_COUNT;
                         DirDelim: char = '\');
    destructor Destroy; override;
  end;

implementation

uses FileCtrl;


function DropTrailingDirDelim(Dir: string; Delim: char = '\'): string;
begin
  if Length(SysUtils.Trim(Dir)) > 0 then
    if Dir[Length(Dir)] = Delim then
      Delete(Dir,Length(Dir),1);
  Result := Dir;
end;


{ TDirectoryStack }

constructor TDirectoryStack.Create;
begin
  inherited Create;
  FDirList := TStringList.Create;
end;

destructor TDirectoryStack.Destroy;
begin
  FDirList.Free;
  inherited Destroy;
end;

function TDirectoryStack.GetCount: integer;
begin
  Result := FDirList.Count;
end;

function TDirectoryStack.GetItem(Index: integer): string;
begin
  Result := '';
  if Index < FDirList.Count then
    Result := FDirList[Index];
end;

function TDirectoryStack.GetSorted: boolean;
begin
  Result := FDirList.Sorted;
end;

function TDirectoryStack.Peek: string;
begin
  Result := '';
  if FDirList.Count > 0 then
    Result := FDirList[FDirList.Count-1];
end;

function TDirectoryStack.Pop: string;
begin
  Result := '-1';
  if FDirList.Count > 0 then
  begin
    Result := FDirList[FDirList.Count-1];
    FDirList.Delete(FDirList.Count-1);
  end;
end;

procedure TDirectoryStack.Push(Dir: string);
begin
  //FDirList.Add(Dir);
  FDirList.Insert(0,Dir);
end;

procedure TDirectoryStack.SetSorted(const Value: boolean);
begin
  if FDirList.Sorted <> Value then
    FDirList.Sorted := Value;
end;



{ TDirs }

constructor TDirs.Create(RootPath: string; Max: integer = MAX_DIR_COUNT;
                         DirDelim: char = '\');
begin
  inherited Create;
  if DirectoryExists(RootPath) then
    FRootPath := DropTrailingDirDelim(RootPath);
  FDirDelim := DirDelim;
  FMaxDirCount := Max;
end;

destructor TDirs.Destroy;
begin
  inherited Destroy;
end;

procedure TDirs.DoOnDirectory(Dir: string);
begin
  if Assigned(FOnDirectory) then
    FOnDirectory(Self,Dir);
end;

procedure TDirs.Enumerate;
begin
  PopulateDirStack;
end;

procedure TDirs.Populate;
begin
  PopulateDirStack;
end;

procedure TDirs.PopulateDirStack;
var
  sr: TSearchRec;
  srRes,i: integer;
  ThisDir: string;
  RootDirs: TDirectoryStack;
begin
  RootDirs := TDirectoryStack.Create;
  try
    //Push(FRootPath);
    if FMaxDirCount > 0 then
    begin
      srRes := FindFirst(FRootPath + FDirDelim + '*.*',faAnyFile,sr);
      try
        while srRes = 0 do
        begin
          if (Count > FMaxDirCount - 1) then Break;
          if ((sr.Attr and faDirectory) = faDirectory) and
             (sr.Name[1] <> '.') then
          begin
            //RootDirs.Push(FRootPath + FDirDelim + sr.Name);
            Push(FRootPath + FDirDelim + sr.Name);
          end;
          srRes := FindNext(sr);
        end;
      finally
        FindClose(sr);
      end;

      //if RootDirs.Count > 0 then
      if Count > 0 then
      begin
        i := 0;
        //while RootDirs.Count > 0 do
        while Count > 0 do
        begin
          //ThisDir := RootDirs.Pop;
          ThisDir := Pop;
          //Push(ThisDir);
          DoOnDirectory(ThisDir);
          srRes := FindFirst(ThisDir + FDirDelim + '*.*',faAnyFile,sr);
          try
            if srRes = 0 then
            begin
              while srRes = 0 do
              begin
                if ((sr.Attr and faDirectory) = faDirectory) and
                   (sr.Name[1] <> '.') then
                begin
                  //RootDirs.Push(ThisDir + FDirDelim + sr.Name);
                  Push(ThisDir + FDirDelim + sr.Name);
                  DoOnDirectory(ThisDir + FDirDelim + sr.Name);
                end;
                srRes := FindNext(sr);
              end;
            end;
          finally
            FindClose(sr);
          end;
        end;
      end;
    end;
  finally
    RootDirs.Free;
  end;
end;

end.
