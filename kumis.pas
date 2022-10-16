unit Kumis;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

const
  DefaultTagBegin = '{{';
  DefaultTagEnd = '}}';
  MAX_SECTION_DEEP = 16;
  CHANGETAG_CHAR = '=';
  CharLookup = '#' {ksSectionBegin} + '?' {ksSectionOnce} +
    '^' {ksSectionInvBegin} + '/' {ksSectionEnd} + CHANGETAG_CHAR {ksChangeTag};

type
  TKumisElType = (ksString, ksVar, ksSectionBegin, ksSectionOnce, ksSectionInvBegin,
    ksSectionEnd, ksChangeTag);

  TKumisEl = record
    AType: TKumisElType;
    Value: string;
    RefElement: integer;
  end;

  TKumisElArr = array of TKumisEl;

  TSectionEvent = function(const AName: string; const Iterator: array of const;
    Data: Pointer): boolean;
  TVariableEvent = function(const AName: string; const Iterator: array of const;
    Data: Pointer): string;

function Parse(const TplStr: string): TKumisElArr;
function Render(const Tpl: TKumisElArr; SectionCb: TSectionEvent;
  VariableCb: TVariableEvent; Data: Pointer = nil): string;

implementation

procedure GrowToSave(var Arr: TKumisElArr; AIndex: SizeInt); inline;
begin
  if AIndex >= Length(Arr) then
    SetLength(Arr, 2 * Length(Arr));
end;

function WalkUntil(const SubStr: string; PFrom, PTo: PChar): PChar;
var
  Limit: PChar;
begin
  Limit := PTo - Length(SubStr);
  while PFrom < Limit do
  begin
    if (PFrom^ = SubStr[1]) and (CompareByte(PFrom^, SubStr[1], Length(SubStr)) = 0) then
    begin
      Result := PFrom;
      Exit;
    end;
    Inc(PFrom);
  end;
  Result := PTo;
end;

function CopyPChar(PFrom, PTo: PChar): string;
var
  L: integer;
begin
  L := PTo - PFrom;
  if L > 0 then
  begin
    SetLength(Result, L);
    Move(PFrom^, Result[1], L);
  end
  else
    Result := '';
end;

procedure SaveToElement(var El: TKumisEl; AType: TKumisElType;
  PFrom, PTo: PChar); inline;
begin
  El.AType := AType;
  El.Value := CopyPChar(PFrom, PTo);
end;

procedure DumpError(PStart, PFrom, PTo: PChar);
begin
  if (PTo - PFrom) > 20 then
    PTo := PFrom + 20;
  raise Exception.CreateFmt('Syntax error around [%d]...%s...',
    [(PFrom - PStart), CopyPChar(PFrom, PTo)]);
end;

function Parse(const TplStr: string): TKumisElArr;
var
  TagBegin, TagEnd: string;
  PStart, PEnd, PTagBegin, PTagEnd, PSpace: PChar;
  ResultCount, CurrentSection: integer;
  ElType: TKumisElType;
begin
  TagBegin := DefaultTagBegin;
  TagEnd := DefaultTagEnd;
  SetLength(Result, 256);
  ResultCount := 0;
  CurrentSection := -1;
  PStart := @TplStr[1];
  PEnd := PStart + Length(TplStr);

  while PStart < PEnd do
  begin
    PTagBegin := WalkUntil(TagBegin, PStart, PEnd);
    if PTagBegin > PStart then
    begin { we find string, save string }
      GrowToSave(Result, ResultCount);
      SaveToElement(Result[ResultCount], ksString, PStart, PTagBegin);
      Inc(ResultCount);
      PStart := PTagBegin;
    end;
    if PTagBegin < PEnd then
    begin { we find TagBegin }
      Inc(PTagBegin, Length(TagBegin));
      PTagEnd := WalkUntil(TagEnd, PTagBegin, PEnd);
      if (PTagEnd < PEnd) and (PTagBegin < PEnd) then
      begin { we find TagBegin and TagEnd }
        PStart := PTagEnd + Length(TagEnd);
        ElType := TKumisElType(Pos(PTagBegin^, CharLookup) + 1);
        case ElType of
          ksString, ksVar:
          begin
            GrowToSave(Result, ResultCount);
            SaveToElement(Result[ResultCount], ElType, PTagBegin, PTagEnd);
            Inc(ResultCount);
          end;
          ksSectionBegin, ksSectionOnce, ksSectionInvBegin:
          begin
            GrowToSave(Result, ResultCount);
            SaveToElement(Result[ResultCount], ElType, PTagBegin + 1, PTagEnd);
            Result[ResultCount].RefElement := CurrentSection;
            CurrentSection := ResultCount;
            Inc(ResultCount);
          end;
          ksSectionEnd:
          begin
            if Result[CurrentSection].AType = ksSectionBegin then
            begin { save section end element }
              GrowToSave(Result, ResultCount);
              SaveToElement(Result[ResultCount], ElType, PTagBegin + 1, PTagEnd);
              Result[ResultCount].RefElement := CurrentSection;
              Inc(ResultCount);
            end;
            with Result[CurrentSection] do
            begin
              CurrentSection := RefElement;
              RefElement := ResultCount;
            end;
          end;
          ksChangeTag:
          begin
            PSpace := WalkUntil(' ', PTagBegin + 1, PTagEnd);
            TagBegin := CopyPChar(PTagBegin + 1, PSpace);
            TagEnd := CopyPChar(PSpace + 1, PTagEnd - 1);
            if ((PTagEnd - 1)^ <> CHANGETAG_CHAR) or (TagBegin = '') or
              (TagEnd = '') then
              DumpError(@TplStr[1], PTagBegin, PEnd);
          end;
        end;
      end
      else
        DumpError(@TplStr[1], PTagBegin, PEnd);
    end;
  end;
  SetLength(Result, ResultCount);
end;

function Render(const Tpl: TKumisElArr; SectionCb: TSectionEvent;
  VariableCb: TVariableEvent; Data: Pointer = nil): string;
var
  P: integer;
  Iterator: array of TVarRec;
  IteratorPos: integer;

  procedure RenderSection(Step: integer; Invert: boolean);
  begin
    Inc(IteratorPos);
    with Iterator[IteratorPos] do
    begin
      VType := vtInteger;
      VInteger := 0;
    end;
    if SectionCb(Tpl[P].Value, Iterator[0..IteratorPos], Data) = Invert then
      P := Tpl[P].RefElement;
    Dec(IteratorPos, 1 - Step);
  end;

begin
  P := 0;
  SetLength(Iterator, MAX_SECTION_DEEP);
  IteratorPos := -1;
  Result := '';
  while P < Length(Tpl) do
  begin
    case Tpl[P].AType of
      ksString:
        Result := Result + Tpl[P].Value;
      ksVar:
        Result := Result + VariableCb(Tpl[P].Value, Iterator[0..IteratorPos], Data);
      ksSectionBegin:
        RenderSection(1, False);
      ksSectionOnce:
        RenderSection(0, False);
      ksSectionInvBegin:
        RenderSection(0, True);
      ksSectionEnd:
      begin
        Inc(Iterator[IteratorPos].VInteger);
        if SectionCb(Tpl[P].Value, Iterator[0..IteratorPos], Data) then
          P := Tpl[P].RefElement
        else
          Dec(IteratorPos);
      end;
      else
        raise Exception.Create('Ilegal element type.');
    end;
    Inc(P);
  end;
end;

end.
