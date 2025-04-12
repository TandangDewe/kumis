program kumistest;

{$mode ObjFPC}{$H+}

uses
  Kumis,
  Classes,
  SysUtils,
  fpjson,
  jsonparser;

function GetSectionJSON(const AName: string; const Iterator: array of const;
  Data: Pointer): boolean;
var
  Node: TJSONData;
  N: String;
begin
  N:= Format(StringReplace(AName,'[]','[%d]',[rfReplaceAll]),Iterator);
  Node := TJSONData(Data).FindPath(N);
  Result := Node <> nil;
  if not Result then
    Exit;
  if ((Node is TJSONBoolean) and not Node.AsBoolean) or (Node is TJSONNull) then
    Exit(False);
  if Node is TJSONArray then
    Result:= Iterator[High(Iterator)].VInteger<Node.Count;
end;

function GetVariableJSON(const AName: string; const Iterator: array of const;
  Data: Pointer): string;
var
  Node: TJSONData;
  N: String;
begin
  N:= Format(StringReplace(AName,'[]','[%d]',[rfReplaceAll]),Iterator);
  Node:= TJSONData(Data).FindPath(N);
  Result:= Node.AsString;
end;

function GetTemplate(const AName: String): TKumisElArr;
var
  TemplateFile: TFileStream = nil;
  TemplateString: String;
begin
  Result:= Nil;
  try
    TemplateFile:= TFileStream.Create(AName+'.tpl',fmOpenRead);
    SetLength(TemplateString,TemplateFile.Size);
    TemplateFile.Read(TemplateString[1],TemplateFile.Size);
    Result:= Parse(TemplateString);
  finally
    TemplateFile.Free;
  end;
end;

function RenderJson(const Tpl: TKumisElArr; Data: TJSONData): String;
begin
  Result:= Render(Tpl,@GetSectionJSON,@GetVariableJSON,@GetTemplate, Data);
end;

procedure Dump(const Tpl: TKumisElArr);
var
  I: integer;
begin
  for I := 0 to Length(Tpl) - 1 do
  begin
    WriteLn('Element #',I);
    WriteLn('  AType      : ',Tpl[I].AType);
    WriteLn('  RefElement : ',Tpl[I].RefElement);
    WriteLn('  Value      : ',StringReplace(Tpl[I].Value,LineEnding,' ',
      [rfReplaceAll]));
  end;
end;

procedure DoTest;
var
  DataFile: TFileStream = nil;
  Data: TJSONData = nil;
  Template: TKumisElArr;
  RenderString: String;
  RenderFile: TFileStream = nil;
begin
  try
    { load json data }
    DataFile := TFileStream.Create('kumis.json', fmOpenRead);
    Data := GetJSON(DataFile);

    { load and parsing template }
    Template:= GetTemplate('kumis');

    { dump }
    Dump(Template);

    { render }
    RenderString:= RenderJson(Template,Data);
    RenderFile:= TFileStream.Create('kumis.html',fmCreate);
    RenderFile.Write(RenderString[1],Length(RenderString));

  finally
    RenderFile.Free;
    Data.Free;
    DataFile.Free;
  end;
end;

begin
  DoTest;
end.
