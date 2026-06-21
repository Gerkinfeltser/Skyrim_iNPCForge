{
  Dumps winning NPC appearance records from the currently loaded xEdit profile.
  Run through MO2 with: /autoload /AllowDirectories /script:"DumpNpcAppearance.pas" /autoexit
}
unit UserScript;

const
  OutputFileName = 'D:\gerkgit\Skyrim_iNPCForge\_tmp\xedit-dumps\npc_appearance_dump.json';

var
  OutLines: TStringList;
  SeenRecords: TStringList;
  FirstRecord: Boolean;
  DumpedCount: Integer;

function JsonEscape(s: string): string;
begin
  Result := s;
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '\t', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\r', [rfReplaceAll]);
end;

function LoadOrderFormID(e: IInterface): string;
begin
  if not Assigned(e) then begin
    Result := '';
    Exit;
  end;

  Result := IntToHex(GetLoadOrderFormID(e), 8);
end;

function RecordLabel(e: IInterface): string;
var
  edid: string;
begin
  if not Assigned(e) then begin
    Result := '';
    Exit;
  end;

  edid := EditorID(e);
  if edid = '' then
    edid := Name(e);

  Result := edid + ' [' + LoadOrderFormID(e) + ':' + GetFileName(GetFile(e)) + ']';
end;

function FieldValue(e: IInterface; path: string): string;
var
  field: IInterface;
begin
  Result := '';

  if not Assigned(e) then
    Exit;

  field := ElementByPath(e, path);
  if Assigned(field) then
    Result := GetEditValue(field);
end;

function LinkValue(e: IInterface; path: string): string;
var
  field: IInterface;
  linked: IInterface;
begin
  Result := '';

  if not Assigned(e) then
    Exit;

  field := ElementByPath(e, path);
  if not Assigned(field) then
    Exit;

  linked := LinksTo(field);
  if Assigned(linked) then
    Result := RecordLabel(linked)
  else
    Result := GetEditValue(field);
end;

function TemplateUsesTraits(e: IInterface): Boolean;
var
  flags: string;
begin
  Result := False;
  flags := FieldValue(e, 'ACBS - Configuration\Template Flags');

  if Pos('Traits', flags) > 0 then
    Result := True;
end;

function AppearanceSource(e: IInterface): IInterface;
var
  source: IInterface;
  templateField: IInterface;
  templateNpc: IInterface;
  guard: Integer;
begin
  source := e;
  guard := 0;

  while Assigned(source) and TemplateUsesTraits(source) and (guard < 16) do begin
    templateField := ElementByPath(source, 'TPLT - Template');
    if not Assigned(templateField) then
      Break;

    templateNpc := LinksTo(templateField);
    if not Assigned(templateNpc) then
      Break;

    source := WinningOverride(templateNpc);
    Inc(guard);
  end;

  Result := source;
end;

procedure AddStringField(indent: string; key: string; value: string; comma: Boolean);
var
  suffix: string;
begin
  suffix := '';
  if comma then
    suffix := ',';

  OutLines.Add(indent + '"' + key + '": "' + JsonEscape(value) + '"' + suffix);
end;

procedure AddLinkedArray(e: IInterface; path: string; key: string; indent: string; comma: Boolean);
var
  container: IInterface;
  item: IInterface;
  linked: IInterface;
  i: Integer;
  suffix: string;
  lineSuffix: string;
  value: string;
begin
  suffix := '';
  if comma then
    suffix := ',';

  OutLines.Add(indent + '"' + key + '": [');

  container := ElementByPath(e, path);
  if Assigned(container) then begin
    for i := 0 to ElementCount(container) - 1 do begin
      item := ElementByIndex(container, i);
      linked := LinksTo(item);

      if Assigned(linked) then
        value := RecordLabel(linked)
      else
        value := GetEditValue(item);

      lineSuffix := ',';
      if i = ElementCount(container) - 1 then
        lineSuffix := '';

      OutLines.Add(indent + '  "' + JsonEscape(value) + '"' + lineSuffix);
    end;
  end;

  OutLines.Add(indent + ']' + suffix);
end;

procedure AddElementArray(e: IInterface; path: string; key: string; indent: string; comma: Boolean);
var
  container: IInterface;
  item: IInterface;
  i: Integer;
  suffix: string;
  lineSuffix: string;
  value: string;
begin
  suffix := '';
  if comma then
    suffix := ',';

  OutLines.Add(indent + '"' + key + '": [');

  container := ElementByPath(e, path);
  if Assigned(container) then begin
    for i := 0 to ElementCount(container) - 1 do begin
      item := ElementByIndex(container, i);
      value := Name(item) + ' = ' + GetEditValue(item);

      lineSuffix := ',';
      if i = ElementCount(container) - 1 then
        lineSuffix := '';

      OutLines.Add(indent + '  "' + JsonEscape(value) + '"' + lineSuffix);
    end;
  end;

  OutLines.Add(indent + ']' + suffix);
end;

procedure DumpNpc(npc: IInterface);
var
  source: IInterface;
  recordKey: string;
begin
  if not Assigned(npc) then
    Exit;

  if Signature(npc) <> 'NPC_' then
    Exit;

  if not Equals(npc, WinningOverride(npc)) then
    Exit;

  recordKey := LoadOrderFormID(npc);
  if SeenRecords.IndexOf(recordKey) >= 0 then
    Exit;
  SeenRecords.Add(recordKey);

  source := AppearanceSource(npc);

  if FirstRecord then
    FirstRecord := False
  else
    OutLines.Add(',');

  OutLines.Add('    {');
  AddStringField('      ', 'formId', LoadOrderFormID(npc), True);
  AddStringField('      ', 'editorId', EditorID(npc), True);
  AddStringField('      ', 'name', FieldValue(npc, 'FULL - Name'), True);
  AddStringField('      ', 'plugin', GetFileName(GetFile(npc)), True);
  AddStringField('      ', 'signature', Signature(npc), True);
  AddStringField('      ', 'template', LinkValue(npc, 'TPLT - Template'), True);
  AddStringField('      ', 'templateFlags', FieldValue(npc, 'ACBS - Configuration\Template Flags'), True);
  AddStringField('      ', 'appearanceSource', RecordLabel(source), True);
  AddStringField('      ', 'race', LinkValue(source, 'RNAM - Race'), True);
  AddStringField('      ', 'sex', FieldValue(source, 'ACBS - Configuration\Flags'), True);
  AddStringField('      ', 'height', FieldValue(source, 'NAM6 - Height'), True);
  AddStringField('      ', 'weight', FieldValue(source, 'NAM7 - Weight'), True);
  AddStringField('      ', 'hairColor', LinkValue(source, 'HCLF - Hair Color'), True);
  AddStringField('      ', 'skin', LinkValue(source, 'WNAM - Worn Armor'), True);
  AddStringField('      ', 'defaultOutfit', LinkValue(source, 'DOFT - Default outfit'), True);
  AddStringField('      ', 'voice', LinkValue(source, 'VTCK - Voice'), True);
  AddStringField('      ', 'class', LinkValue(source, 'CNAM - Class'), True);
  AddStringField('      ', 'faceMorph', FieldValue(source, 'NAM9 - Face morph'), True);
  AddLinkedArray(source, 'Head Parts', 'headParts', '      ', True);
  AddElementArray(source, 'Tint Layers', 'tintLayers', '      ', False);
  OutLines.Add('    }');

  Inc(DumpedCount);
end;

procedure ProcessNpcGroup(group: IInterface);
var
  i: Integer;
begin
  if not Assigned(group) then
    Exit;

  for i := 0 to ElementCount(group) - 1 do
    DumpNpc(ElementByIndex(group, i));
end;

procedure ProcessFile(fileRef: IInterface);
var
  npcGroup: IInterface;
begin
  npcGroup := GroupBySignature(fileRef, 'NPC_');
  ProcessNpcGroup(npcGroup);
end;

function Initialize: Integer;
var
  i: Integer;
begin
  OutLines := TStringList.Create;
  SeenRecords := TStringList.Create;
  SeenRecords.Sorted := True;
  SeenRecords.Duplicates := dupIgnore;
  FirstRecord := True;
  DumpedCount := 0;

  OutLines.Add('{');
  OutLines.Add('  "generatedBy": "DumpNpcAppearance.pas",');
  OutLines.Add('  "mode": "winning NPC_ overrides from loaded xEdit profile",');
  OutLines.Add('  "records": [');

  for i := 0 to FileCount - 1 do
    ProcessFile(FileByIndex(i));

  OutLines.Add('');
  OutLines.Add('  ]');
  OutLines.Add('}');
  OutLines.SaveToFile(OutputFileName);

  AddMessage('DumpNpcAppearance wrote ' + IntToStr(DumpedCount) + ' NPC records to ' + OutputFileName);

  Result := 0;
end;

function Finalize: Integer;
begin
  OutLines.Free;
  SeenRecords.Free;
  Result := 0;
end;

end.
