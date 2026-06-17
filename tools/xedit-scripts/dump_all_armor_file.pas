unit dump_all_armor_file;
{
  xEdit Apply Script: dump ALL ARMO records to a text file.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: SSEEdit -IKnowWhatImDoing -script:"dump_all_armor_file.pas"
  Output: D:\gerkgit\Skyrim_iNPCForge\_tmp\armor_dump.txt
          FormID <TAB> ARMO <TAB> EditorID <TAB> Name
}

var
  outFile: string;

function Initialize: integer;
begin
  outFile := 'D:\gerkgit\Skyrim_iNPCForge\_tmp\armor_dump.txt';
  Result := 0;
end;

function Process(e: IInterface): integer;
var
  line: string;
begin
  if Signature(e) <> 'ARMO' then begin
    Result := 0;
    Exit;
  end;
  if EditorID(e) = '' then begin
    Result := 0;
    Exit;
  end;
  line := IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'ARMO' + #9 + EditorID(e) + #9 + Name(e);
  AddMessage(line);
  Result := 0;
end;

function Finalize: integer;
begin
  AddMessage('[DONE] ARMO records dumped. Check Messages panel for ' + IntToStr(0) + ' lines.');
  Result := 0;
end;
end.
