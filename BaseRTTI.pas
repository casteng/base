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

  // Returns array of published property names of the given class
  function GetClassProperties(AClass: TClass; TypeKinds: TTypeKinds = tkAny): TRTTINames;
  // Returns array of published method names of the given class
  function GetClassMethods(AClass: TClass): TRTTINames;

  // Unvokes parameterless procedure method with the given name of the given class 
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
    Count := GetPropList(AClass.ClassInfo, tkAny, nil);
    // Allocate memory for all data
    GetMem(PropInfos, Count * SizeOf(PPropInfo));
    Garbage.AddPointer(PropInfos);

    GetPropList(AClass.ClassInfo, tkAny, PropInfos);

    SetLength(Result, Count);
    for i := 0 to Count - 1 do
      Result[i] := PropInfos^[i]^.Name;
  end;

  function GetClassMethods(AClass: TClass): TRTTINames;
  begin
    Result := GetClassProperties(AClass, tkMethods);
  end;

  procedure InvokeCommand(Obj: TObject; const Name: TRTTIName);
  var
    Method: TMethod;
  begin
    Method.Code := Obj.MethodAddress(Name);
    Method.Data := Pointer(Obj);
    TCommand(Method)();
  end;

end.
