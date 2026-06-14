unit dump_packages;
{
  xEdit Apply Script: dump PACK (AI package) records from Skyrim.esm.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: xEdit -> right-click Skyrim.esm -> Apply Script... -> browse here
  Output: FormID <TAB> EditorID <TAB> Name (Messages panel)

  Purpose: verify AI package (PACK) FormIDs for NPC AI assignments.
  Sandbox package (DefaultSandboxEditorLink) is critical for friendly NPCs.
}

function Process(e: IInterface): integer;
var
  sig: string;
begin
  sig := Signature(e);

  if sig = 'PACK' then begin
    AddMessage(
      IntToHex(GetLoadOrderFormID(e), 8) + #9 +
      EditorID(e) + #9 +
      Name(e)
    );
  end;

  Result := 0;
end;

end.
