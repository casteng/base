(*
  @Abstract(RTTI support unit unit)
  (C) 2003-2012 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  Created: Jan 19, 2012
  The unit contains routines to easily use of RTTI
*)
{$Include GDefines.inc}
unit BaseRTTI;

interface

  uses TypInfo;

  type
    TRTTIName = ShortString;
    TRTTINames = array of TRTTIName;

  // Returns array of published property names of the given class and its parent classes
  function GetClassProperties(AClass: TClass; TypeKinds: TTypeKinds = tkAny): TRTTINames;
  {  Returns array of published method names of the given class.
     If ScanParents is True published methods of parent classes are also included. }
  function GetClassMethods(AClass: TClass; ScanParents: Boolean): TRTTINames;

  // Invokes parameterless procedure method with the given name of the given class
  procedure InvokeCommand(Obj: TObject; const Name: TRTTIName);

implementation

  uses BaseTypes, Basics;

  function GetClassProperties(AClass: TClass; TypeKinds: TTypeKinds = tkAny): TRTTINames;
  var
    Garbage: IRefcountedContainer;
    PropInfos: PPropList;
    Count, i: Integer;
  begin
    Garbage := CreateRefcountedContainer();
    // Get count of published properties
    Count := GetPropList(AClass.ClassInfo, TypeKinds, nil);
    // Allocate memory for all data
    GetMem(PropInfos, Count * SizeOf(PPropInfo));
    Garbage.AddPointer(PropInfos);

    GetPropList(AClass.ClassInfo, TypeKinds, PropInfos);

    SetLength(Result, Count);
    for i := 0 to Count - 1 do
      Result[i] := PropInfos^[i]^.Name;
  end;

  type
    {$IFDEF FPC}
      TMethodCount = LongWord;
      TMethodNameRec = packed record
        Name: PShortString;
        Address: Pointer;
      end;
    {$ELSE}
      TMethodCount = Word;
      TMethodNameRec = packed record
        Size: Word;
        Address: Pointer;
        Name: ShortString;
      end;
    {$ENDIF}

    PMethodNameRec = ^TMethodNameRec;
    PMethodNameTable = ^TMethodNameTable;
    TMethodNameTable = packed record
      Count: TMethodCount;
      Methods: TMethodNameRec;
    end;

  procedure AddMethods(MethodTable: PMethodNameTable; var Names: TRTTINames);
  var
    i, Offs, Count: Integer;
    MethodRec: PMethodNameRec;
  begin
    if MethodTable <> nil then begin
      Offs := Length(Names);
      Count := MethodTable^.Count;
      SetLength(Names, Offs + Count);

      MethodRec := @MethodTable^.Methods;

      for i := 0 to Count - 1 do begin
        {$IFDEF FPC}
          Names[Offs + i] := MethodRec^.Name^;
          Inc(MethodRec);
        {$ELSE}
          Names[Offs + i] := MethodRec^.Name;
          MethodRec := PtrOffs(MethodRec, MethodRec^.Size);
        {$ENDIF}
      end;
    end;
  end;

  function GetClassMethods(AClass: TClass; ScanParents: Boolean): TRTTINames;
  var
    MethodTable: PMethodNameTable;
  begin
    MethodTable := PPointer(Integer(Pointer(AClass)) + vmtMethodTable)^;
    AddMethods(MethodTable, Result);

    AClass := AClass.ClassParent;
    while ScanParents and (AClass <> nil) do begin
      MethodTable := PPointer(PtrOffs(AClass, vmtMethodTable))^;
      AddMethods(MethodTable, Result);
      AClass := AClass.ClassParent;
    end;
  end;

  procedure InvokeCommand(Obj: TObject; const Name: TRTTIName);
  var
    Method: TMethod;
  begin
    if not Assigned(Obj) then Exit;
    Method.Code := Obj.MethodAddress(Name);
    Method.Data := Pointer(Obj);
    TCommand(Method)();
  end;

end.
