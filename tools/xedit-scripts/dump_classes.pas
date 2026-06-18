unit dump_classes;
{
  xEdit Apply Script: dump CLAS (class) records from the selected plugin.
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: xEdit -> right-click source plugin -> Apply Script... -> browse here
  Output: FormID <TAB> CLAS <TAB> EditorID <TAB> Name (Messages panel)

  Purpose: verify NPC Class field references such as WarriorClass.
}

function Process(e: IInterface): integer;
begin
  if Signature(e) <> 'CLAS' then begin
    Result := 0;
    Exit;
  end;

  if EditorID(e) = '' then begin
    Result := 0;
    Exit;
  end;

  AddMessage(
    IntToHex(GetLoadOrderFormID(e), 8) + #9 +
    'CLAS' + #9 +
    EditorID(e) + #9 +
    Name(e)
  );

  Result := 0;
end;

end.
