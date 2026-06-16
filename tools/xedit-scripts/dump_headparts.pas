unit dump_headparts;
{
  xEdit Apply Script: dump ALL HDPT (headpart) records from Skyrim.esm.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: SSEEdit -IKnowWhatImDoing -script:"dump_headparts.pas"
  Output: FormID <TAB> HDPT <TAB> EditorID <TAB> Name <TAB> Type (Messages panel)
  Type: Hair, Eyes, FacialHair, Scar, Brows, etc.
}

function Process(e: IInterface): integer;
var
  t: integer;
  typeName: string;
begin
  if Signature(e) <> 'HDPT' then begin
    Result := 0;
    Exit;
  end;
  if EditorID(e) = '' then begin
    Result := 0;
    Exit;
  end;
  t := GetElementNativeValues(e, 'Type');
  if t = 0 then typeName := 'Misc'
  else if t = 1 then typeName := 'Head'
  else if t = 2 then typeName := 'Eye'
  else if t = 3 then typeName := 'Hair'
  else if t = 4 then typeName := 'FacialHair'
  else if t = 5 then typeName := 'Scar'
  else if t = 6 then typeName := 'Brows'
  else typeName := 'Other';
  AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'HDPT' + #9 + EditorID(e) + #9 + Name(e) + #9 + typeName);
  Result := 0;
end;
end.
