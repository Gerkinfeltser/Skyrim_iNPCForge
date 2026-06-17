unit dump_weapons_file;

var
  outFile: TStringList;

function Initialize: integer;
begin
  outFile := TStringList.Create;
  Result := 0;
end;

function Process(e: IInterface): integer;
begin
  if Signature(e) <> 'WEAP' then begin
    Result := 0;
    Exit;
  end;
  if EditorID(e) = '' then begin
    Result := 0;
    Exit;
  end;
  outFile.Add(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'WEAP' + #9 + EditorID(e) + #9 + Name(e));
  Result := 0;
end;

function Finalize: integer;
begin
  outFile.SaveToFile('D:\gerkgit\Skyrim_iNPCForge\_tmp\weapon_dump.txt');
  AddMessage('[DONE] Saved ' + IntToStr(outFile.Count) + ' WEAP records to _tmp\weapon_dump.txt');
  outFile.Free;
  Result := 0;
end;
end.
