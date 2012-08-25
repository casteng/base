{
 @Abstract(Item properties support unit)
 (C) 2004 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains a generic properties support implementation
}
{$Include GDefines.inc}
unit Props;

interface

uses
  Logger,
  BaseTypes, Basics, BaseStr, json;

type TPropertyValueType = Integer;

const
  // Properties collection grow step
  PropsCapacityStep = 32;
  // File signature 
  PropertiesFileSignature: TFileSignature = 'PC00';
    // Possible value types
  // No value
  vtNone = 0;
  // Unsigned integer (natural) value
  vtNat = 1;
  // Integer value
  vtInt = 2;
  // Single-precision floating-point value
  vtSingle = 3;
  // Double-precision floating-point value
  vtDouble = 10;
  // AnsiString value
  vtString     = 4;
  // Color value
  vtColor      = 5;
  // Boolean value
  vtBoolean    = 6;
  // Enumerated value. Enumeration used to specify possible options.
  vtEnumerated = 7;
  // A link to an object
  vtObjectLink = 8;
  // Bynary data. Enumeration used to specify data size. Memory for the data managed mostly by application (see @Link(RetrieveBinPropertyData)).
  vtBinary     = 9;
  // Numerical (2xSingle) sample data. Enumeration used to specify data size. Memory for the data managed mostly by application (see @Link(RetrieveBinPropertyData)).
  vtSingleSample = 11;
  // Color gradient (Single + TColor) sample data. Enumeration used to specify data size. Memory for the data managed mostly by application (see @Link(RetrieveBinPropertyData)).
  vtGradientSample = 12;
    // Boolean value indices
  // Off, no, etc
  bvOff = 0;
  // On, yes, etc
  bvOn = 1;
  // Boolean value strings
  OnOffStr: array[False..True] of string[3] = ('Off', 'On');
  // Boolean values enumeration
  OnOffEnum = 'Off' + StringDelimiter + 'On';

  // For converting JSON to properties
  JSONToPropertyType: array[TJSONValueType] of Integer=(vtString, vtDouble, vtBoolean, vtObjectLink, vtNone);


type
  // Type for property names
  TPropertyName = AnsiString;
  // Type for property values
  TPropertyValue = AnsiString;
  // Type of value
  TValueType = Integer;
  // Possible property options
  TPOption = (// the property is hidden in an editor
              poHidden,
              // the property is read-only
              poReadonly,
              // the property is a derivative from other values so can not be changed directly
              poDerivative,
              // forces the set to be 32-bit
              poDecor = 31);
  // Property options set
  TPOptions = set of TPOption;

  PProperty = ^TProperty;
  { Property data structure. <br>
    <b>Name</b> - property name. Should be unique within @Link(TProperties). <br>
    <b>Value</b> - property value. <br>
    <b>Enumeration</b> - a set of string values, separated by <b>StringDelimiter</b>, determining possible values for <b>Value</b>. <br>
    <b>Description</b> - property description. <br>
    <b>ValueType</b> - property value type. <br>
    <b>Options</b> - property option set. }
  TProperty = packed record
    Name: TPropertyName;
    Value, Enumeration: TPropertyValue;
    Description: AnsiString;
    ValueType: TValueType;
    Options: TPOptions;
  end;

  // A delegate used in <b>ForEach</b> method
  TPropertyDelegate = function(const Key: TProperty; var CustomData: Integer): Boolean of object;

  // @Abstract(Main properties class)
  TProperties = class
  private
    FTempBuffers: array of Pointer;
    function IsBinary(ValueType: TValueType): Boolean;
    // Sets the value of the specified property
    procedure SetValueProc(const Name: TPropertyName; const Value: TPropertyValue);
    function GetTempIndex(Data: Pointer): Integer;

    procedure JSONData(const Obj: TJSON; const Name: TJSONString; Value: TJSONValue);
  protected
    // Number of properties
    FTotalProperties: Integer;
    // Set of properties
    Properties: array of TProperty;
    // Returns the index of the specified property
    function GetIndex(const Name: TPropertyName): Integer; virtual;
    // Returns the value of the specified by index property
    function GetValueByIndex(Index: Integer): AnsiString; virtual;
    // Returns the value of the specified property
    function GetValue(const Name: TPropertyName): AnsiString;
    // Sets the value of the specified by index property
    procedure SetValueByIndex(Index: Integer; const Value: AnsiString);
    // Sets the value of the specified property
    function SetValue(const Name: TPropertyName; const Value: AnsiString): Integer; virtual;

    // Returns an integer representation of the value with the specified type and enumeration
    function ValueToInteger(ValueType: Integer; const Value, Enumeration: AnsiString): Int32; virtual;
    // Returns a floating-point representation of the value with the specified type and enumeration
    function ValueToFloat(const Value: AnsiString): Extended; virtual;
    // Sets the value index of the specified by index enumerated property
    procedure SetEnumeratedValueByIndex(Index, ValueIndex: Integer);

    // Returns a pointer to the property data structure by property index
    function GetPropertyByIndex(const Index: Integer): PProperty; virtual;
  public
    // This field becomes True with any change of properties or values
    Changed: Boolean;

    // Create an empty instance
    constructor Create(); overload;
    // Creates an instance and fills it with name/value pairs from a JSON data
    constructor Create(const jsonStr: TJSONString); overload;
    destructor Destroy; override;

    // Calls the <b>Action</b> delegate for each property
    procedure DoForEach(Action: TPropertyDelegate; var CustomData: Integer);

    // Adds a properties set specified by <b>Props</b> to the current set. If OverrideExisting is True existing values will be overridden by the new ones with the same name.
    procedure Merge(const Props: TProperties; OverrideExisting: Boolean);

    // Returns True if the both properties are equal
    function IsEqualProperty(const Prop1, Prop2: TProperty): Boolean; {$I inline.inc}
    // Returns True if both property sets are equal
    function IsEqual(const Props: TProperties): Boolean;

    // Returns @True if a property with the specified name exists in the set
    function Exists(const Name: TPropertyName): Boolean;
    // Returns @True if a property with the specified name exists and has a valid value
    function Valid(const Name: TPropertyName): Boolean; virtual;

    // Returns property name by its index
    function GetNameByIndex(const Index: Integer): TPropertyName; virtual;

    // Returns a pointer to property by its name or nil if it is not found
    function GetProperty(const Name: TPropertyName): PProperty; virtual;

    { Moves a binary property data to a previously allocated Dest and frees memory referenced by property value.
      Returns size of the binary property in elements or zero if no property or data found. }
    function RetrieveBinPropertyData(const PropName: TPropertyName; Dest: Pointer): Integer;
    // Returns size of the specified binary property in elements of the specified size
    function GetBinPropertySize(const PropName: TPropertyName; ElementSize: Integer): Integer;

    // Returns an integer representation of the properties value
    function GetAsInteger(const Name: TPropertyName): Integer; virtual;
    // Returns property value type
    function GetType(const Name: TPropertyName): TPropertyValueType; virtual;
    // Returns property value type as string
    function GetTypeAsString(Index: Integer): AnsiString; virtual;
    // Returns property option set
    function GetOptions(const Name: TPropertyName): TPOptions; virtual;

    // Adds a new property to the set and returns its index
    function Add(const AName: TPropertyName; const AValueType: Integer; const AOptions: TPOptions; const AValue, AEnumeration: AnsiString; const ADescription: AnsiString = ''): Integer;
    // Adds a new enumerated property to the set and returns its index
    function AddEnumerated(const AName: TPropertyName; const AOptions: TPOptions; AValue: Integer; const AEnumeration: AnsiString): Integer;
    { Adds a new binary property to the set and returns its index. AData should stay valid during the properties lifetime.
      if @Link(RetrieveBinPropertyData) function is used to retrieve the data, no part of dynamic array or other managed memory can be passed in AData }
    function AddBinary(const AName: TPropertyName; const AOptions: TPOptions; AData: Pointer; DataSize: Integer): Integer;
    { Adds a variable of a set type as a set of boolean values to the current property set. <br>
      <b>VisibleMembers</b> is a set of members which should be added. If it's empty all members will be added. }
    procedure AddSetProperty(const Name: TPropertyName; Value, VisibleMembers: TSet32; ValuesEnum: TAnsiStringArray; const ADescription: AnsiString); overload;
    // Sets a set of boolean properties added by @Link(AddSetProperty) with the specified set variable
    function SetSetProperty(const Name: TPropertyName; var Res: TSet32; ValuesEnum: TAnsiStringArray): Boolean; overload;
    { Adds a variable of a set type as a set of boolean values to the current property set. <br>
      <b>VisibleMembers</b> is a set of members which should be added. If it's empty all members will be added. }
    procedure AddSetProperty(const Name: TPropertyName; Value, VisibleMembers: TSet32; const ValuesEnum, ADescription: TPropertyValue); overload;
    // Sets a set of boolean properties added by @Link(AddSetProperty) with the specified set variable
    function SetSetProperty(const Name: TPropertyName; var Res: TSet32; const ValuesEnum: TPropertyValue): Boolean; overload;

    // Returns the properties in XML format
    function GetAsXML: AnsiString; virtual;

    // Writes the properties to a stream and return @True if success
    function Write(Stream: TStream): Boolean; virtual;
    // Reads the properties from a stream and return @True if success
    function Read(Stream: TStream): Boolean; virtual;

    { Delegates control of memory block occupied by a binary data to application. The memory block identified by pointer.
      Typically the data valid as long as TProperties object which contains the property. After call of this procedure application should free the data by itself. }
    procedure AcquireData(Data: Pointer);
    { Creates temporary copy of memory buffer or a new memory buffer if Src is nil and returns a pointer to the copy.
      The copy will be automatically destroyed when used by RetrieveBinPropertyData or while clearing or destroying TProperties instance.
      Should be used with binary properties to pass in AddBinary()-like methods. }
    function TempCopy(Src: Pointer; Size: Integer): Pointer;
    { Finds and frees a previously created temporary memory buffer and returns True if it was found and freed }
    function FindAndFreeTemp(Data: Pointer): Boolean;

    // Clear the current property set as well as temporal memory storage
    procedure Clear; virtual;

    property TotalProperties: Integer read FTotalProperties;
    // Property values by names
    property Values[const Name: TPropertyName]: TPropertyValue read GetValue write SetValueProc; default;
  end;

  // Base file configuration class
  TBaseFileConfig = class(TProperties)
  private
    FileName: BaseTypes.TFileName;
  public
    constructor Create(const AFileName: BaseTypes.TFileName);
    constructor CreateFromFile(const AFileName: BaseTypes.TFileName);
    function SaveAs(const AFilename: BaseTypes.TFileName): Boolean; virtual; abstract;
    function LoadFrom(const AFilename: BaseTypes.TFileName): Boolean; virtual; abstract;
    function Save: Boolean;
    function Load: Boolean;
  end;

  // File configuration implementation class
  TFileConfig = class(TBaseFileConfig)
    function SaveAs(const AFilename: BaseTypes.TFileName): Boolean; override;
    function LoadFrom(const AFilename: BaseTypes.TFileName): Boolean; override;
  end;

  // File configuration implementation which preserves tabs, spaces and commented lines in the configuration file
  TNiceFileConfig = class(TBaseFileConfig)
  protected
    function GetIndex(const Name: AnsiString): Integer; override;
    function GetValueByIndex(Index: Integer): AnsiString; override;
  public
    function GetNameByIndex(const Index: Integer): AnsiString; override;
    function SaveAs(const AFilename: BaseTypes.TFileName): Boolean; override;
    function LoadFrom(const AFilename: BaseTypes.TFileName): Boolean; override;
  end;

  procedure CopyProperty(const SrcProp: TProperty; var DestProp: TProperty);
  // Adds to <b>Properties</b> a <b>TColor4s</b> value as four floating-point components and one color property
  procedure AddColor4sProperty(Properties: TProperties; const Name: AnsiString; const Color: TColor4s);
  // Adds to <b>Properties</b> a <b>TColor</b> value as four floating-point components and one color property
  procedure AddColorProperty(Properties: TProperties; const Name: AnsiString; const Color: TColor);
  { Sets a color property in <b>Properties</b> with the given in <b>Res</b> value. <br>
    Returns the resulting value in <b>Res</b> and @True if new <b>Res</b> value differs from the initial one }
  function SetColor4sProperty(Properties: TProperties; const Name: AnsiString; var Res: TColor4s): Boolean;
  { Sets a color property in <b>Properties</b> with the given in <b>Res</b> value. <br>
    Returns the resulting value in <b>Res</b> and @True if new <b>Res</b> value differs from the initial one }
  function SetColorProperty(Properties: TProperties; const Name: AnsiString; var Res: TColor): Boolean;


implementation

uses SysUtils;

procedure CopyProperty(const SrcProp: TProperty; var DestProp: TProperty);
begin
  with DestProp do begin
    Name        := SrcProp.Name;
    Value       := SrcProp.Value;
    Enumeration := SrcProp.Enumeration;
    Description := SrcProp.Description;
    ValueType   := SrcProp.ValueType;
    Options     := SrcProp.Options;
  end;
end;

procedure AddColor4sProperty(Properties: TProperties; const Name: AnsiString; const Color: TColor4s);
begin
  Properties.Add(Name,            vtColor,  [], '#' + IntToHexA(GetColorFrom4S(Color).C, 8), '');
  Properties.Add(Name + '\Red',   vtSingle, [], FormatA('%1.3F', [Color.R]), '0-1');
  Properties.Add(Name + '\Green', vtSingle, [], FormatA('%1.3F', [Color.G]), '0-1');
  Properties.Add(Name + '\Blue',  vtSingle, [], FormatA('%1.3F', [Color.B]), '0-1');
  Properties.Add(Name + '\Alpha', vtSingle, [], FormatA('%1.3F', [Color.A]), '0-1');
end;

procedure AddColorProperty(Properties: TProperties; const Name: AnsiString; const Color: TColor);
begin
  AddColor4sProperty(Properties, Name, ColorTo4S(Color));
end;

function SetColor4sProperty(Properties: TProperties; const Name: AnsiString; var Res: TColor4s): Boolean;
var NewVec: TColor4s;
begin
  NewVec := Res;
  if Properties.Valid(Name)            then NewVec   := ColorTo4S(Nat32(Properties.GetAsInteger(Name)));
  if Properties.Valid(Name + '\Red')   then NewVec.R := StrToFloatDefA(Properties[Name + '\Red'],   0.5);
  if Properties.Valid(Name + '\Green') then NewVec.G := StrToFloatDefA(Properties[Name + '\Green'], 0.5);
  if Properties.Valid(Name + '\Blue')  then NewVec.B := StrToFloatDefA(Properties[Name + '\Blue'],  0.5);
  if Properties.Valid(Name + '\Alpha') then NewVec.A := StrToFloatDefA(Properties[Name + '\Alpha'], 0.5);
  Result := isNan(Res.R) or isNan(Res.G) or isNan(Res.B) or isNan(Res.A) or
           (NewVec.R <> Res.R) or (NewVec.G <> Res.G) or (NewVec.B <> Res.B) or (NewVec.A <> Res.A);
  if Result then Res := NewVec;
end;

function SetColorProperty(Properties: TProperties; const Name: AnsiString; var Res: TColor): Boolean;
var V: TColor4s;
begin
  V := ColorTo4S(Res);
  Result := SetColor4sProperty(Properties, Name, V);
  if Result then Res := GetColorFrom4s(V);
end;

function PropertyOptionsToString(const Options: TPOptions): AnsiString;
begin
  Result := '';
  if poHidden in Options then Result := 'Hidden';
  if poReadonly in Options then begin
    if Result <> '' then  Result := Result + ', ';
    Result := Result + 'Readonly';
  end;
end;

{ TProperties }

procedure TProperties.DoForEach(Action: TPropertyDelegate; var CustomData: Integer);
var i: Integer;
begin
  if @Action <> nil then for i := 0 to FTotalProperties-1 do if not Action(Properties[i], CustomData) then Exit;
end;

procedure TProperties.Merge(const Props: TProperties; OverrideExisting: Boolean);
var i, ind: Integer; DataValue: AnsiString;
begin
  if Assigned(Props) then
    for i := 0 to Props.FTotalProperties-1 do
      if OverrideExisting or not Exists(Props.Properties[i].Name) then begin
        if IsBinary(Props.Properties[i].ValueType) then begin
          ind := Props.GetTempIndex(Pointer(StrToIntDef(Props.Properties[i].Value, 0)));
          if ind >= 0 then
            DataValue := IntToStrA(Cardinal( TempCopy(Props.FTempBuffers[ind], StrToIntDef(Props.Properties[i].Enumeration, 0)) ))
          else
            DataValue := Props.Properties[i].Value;
        end else
          DataValue := Props.Properties[i].Value;
        Properties[Add(Props.Properties[i].Name, Props.Properties[i].ValueType, Props.Properties[i].Options, DataValue, Props.Properties[i].Enumeration)].Description := Props.Properties[i].Description;
      end;
end;

function TProperties.IsEqualProperty(const Prop1, Prop2: TProperty): Boolean;
begin
  Result := (Prop1.ValueType = Prop2.ValueType) and (Prop1.Options = Prop2.Options) and
            (Prop1.Name = Prop2.Name) and (Prop1.Value = Prop2.Value) and
            (Prop1.Enumeration = Prop2.Enumeration) and (Prop1.Description = Prop2.Description);
end;

procedure TProperties.JSONData(const Obj: TJSON; const Name: TJSONString; Value: TJSONValue);
begin
  Add(Name, JSONToPropertyType[Value.ValueType], [], Value.asStr, '');
end;

function TProperties.IsEqual(const Props: TProperties): Boolean;
var i: Integer;
begin
  Result := False;
  if TotalProperties <> Props.TotalProperties then Exit;
  i := TotalProperties;
  while (i >= 0) and Props.Exists(Properties[i].Name) and IsEqualProperty(Properties[i], Props.GetProperty(Properties[i].Name)^) do Dec(i);
  Result := i < 0;
end;

function TProperties.Exists(const Name: AnsiString): Boolean;
// Returns TRUE if property with this name exists, FALSE otherwise
begin
  Result := GetIndex(Name) > -1;
end;

function TProperties.Valid(const Name: AnsiString): Boolean;
var Index, i: Integer; Enums: TAnsiStringArray; TotalEnums: Integer; Val64: Int64;
begin
  Result := False;
  Index := GetIndex(Name);
  if Index = -1 then Exit;                                          // Return invalid if not exists
  case Properties[Index].ValueType of
    vtNat: begin
       Val64 := StrToInt64Def(GetValueByIndex(Index), -1);
       Result := (Val64 >= 0) and (Val64 <= MaxNat32);
    end;
    vtInt:    Result := IsDecimalInteger(GetValueByIndex(Index));
    vtSingle,
    vtDouble: Result := IsFloat(GetValueByIndex(Index));
    vtString,
    vtObjectLink,
    vtBinary: Result := True;
    vtSingleSample, vtGradientSample: Result := True;//(StrToIntDef(Properties[Index].Enumeration, -1) mod (SizeOf(Single)*2)) = 0;
    vtColor:  Result := IsColor(GetValueByIndex(Index));
    vtBoolean,
    vtEnumerated: begin
      TotalEnums := SplitA(Properties[Index].Enumeration, StringDelimiter, Enums, True);
      Result := False;
      for i := 0 to TotalEnums-1 do if Enums[i] = GetValueByIndex(Index) then begin
        Result := True; Break;
      end;
      Enums := nil;
    end;
    else Result := False;
  end;
end;

function TProperties.GetProperty(const Name: AnsiString): PProperty;
var Index: Integer;
begin
  Index := GetIndex(Name);
  if Index > -1 then Result := @Properties[Index] else Result := nil;
end;

function TProperties.RetrieveBinPropertyData(const PropName: AnsiString; Dest: Pointer): Integer;
var Temp: Pointer; Prop: PProperty;
begin
  Prop := GetProperty(PropName);
//  Assert(Prop^.ValueType = vtBinary);
  Result := StrToIntDef(Prop^.Enumeration, 0);
  Temp := Pointer(StrToIntDef(Prop^.Value, 0));
  if not Assigned(Temp) or (Result = 0) then Exit;

  if Assigned(Dest) then Move(Temp^, Dest^, Result);
  FindAndFreeTemp(Temp);                                                        // Free temporary property data
//    FreeMem(Temp);
end;

function TProperties.GetBinPropertySize(const PropName: AnsiString; ElementSize: Integer): Integer;
var Prop: PProperty;
begin
  Assert(ElementSize > 0);
  Prop := GetProperty(PropName);
//  Assert(Prop^.ValueType = vtBinary);
  if Assigned(Prop) then
    Result := StrToIntDef(Prop^.Enumeration, 0)
  else
    Result := 0;

  if Result mod ElementSize = 0 then
    Result := Result div ElementSize
  else
    Result := 0;
end;

function TProperties.GetNameByIndex(const Index: Integer): AnsiString;
begin
  if (Index >= 0) and (Index < FTotalProperties) then
    Result := Properties[Index].Name
  else
    Result := '';
end;

function TProperties.GetPropertyByIndex(const Index: Integer): PProperty;
begin
  if (Index >= 0) and (Index < FTotalProperties) then begin
    Result := @Properties[Index];
  end else Result := nil;
end;

function TProperties.GetValue(const Name: AnsiString): AnsiString;
// Returns value of property with given name
var i: Integer;
begin
  i := GetIndex(Name);
  if i > -1 then Result := GetValueByIndex(i) else Result := '';
end;

function TProperties.GetAsInteger(const Name: AnsiString): Integer;
var Index: Integer;
begin
  Result := 0;
  Index := GetIndex(Name);
  if Index = -1 then Exit;
  Result := ValueToInteger(Properties[Index].ValueType, GetValueByIndex(Index), Properties[Index].Enumeration);
end;

function TProperties.GetType(const Name: AnsiString): TPropertyValueType;
// Returns type of property with the given name
var i: Integer;
begin
  i := GetIndex(Name);
  if i > -1 then Result := Properties[i].ValueType else Result := 0;
end;

function TProperties.GetTypeAsString(Index: Integer): AnsiString;
begin
  case Properties[Index].ValueType of
    vtNat:            Result := 'Unsigned';
    vtInt:            Result := 'Integer';
    vtSingle:         Result := 'Real';
    vtDouble:         Result := 'Double';
    vtString:         Result := 'String';
    vtObjectLink:     Result := 'Object link';
    vtBinary:         Result := 'Binary data';
    vtSingleSample:   Result := 'Sampled data';
    vtGradientSample: Result := 'Sampled gradient';
    vtColor:          Result := 'Color';
    vtBoolean:        Result := 'Boolean';
    vtEnumerated:     Result := 'Enumerated';
    else              Result := 'Unknown';
  end;
end;

function TProperties.GetOptions(const Name: TPropertyName): TPOptions;
// Returns options of property with given name
var i: Integer;
begin
  i := GetIndex(Name);
  if i > -1 then Result := Properties[i].Options else Result := [];
end;

function TProperties.Add(const AName: TPropertyName; const AValueType: Integer; const AOptions: TPOptions; const AValue, AEnumeration: AnsiString; const ADescription: AnsiString = ''): Integer;
// Adds a new property into list
// Returns index of the new property
begin
  Result := GetIndex(AName);

//  if  = nil then SetLength(Properties, 1000000);

  if Result = -1 then begin
    Inc(FTotalProperties); //SetLength(Properties, FTotalProperties);
    Result := FTotalProperties-1;
    if Length(Properties) < FTotalProperties then SetLength(Properties, Length(Properties) + PropsCapacityStep);
  end;
  Properties[Result].Name        := AName;
  Properties[Result].ValueType   := AValueType;
  Properties[Result].Options     := AOptions;
  Properties[Result].Enumeration := AEnumeration;
  Properties[Result].Description := ADescription;
  SetValueByIndex(Result, AValue);

  if AValueType = vtBoolean then Properties[Result].Enumeration := OnOffEnum; // Handle Boolean value type as enumerated type

  Changed := True;
end;

function TProperties.AddEnumerated(const AName: TPropertyName; const AOptions: TPOptions; AValue: Integer; const AEnumeration: AnsiString): Integer;
begin
  Result := Add(AName, vtEnumerated, AOptions, '', AEnumeration);
  // Set enumerated value to one from list using given value as index
  SetEnumeratedValueByIndex(Result, AValue);
end;

function TProperties.AddBinary(const AName: TPropertyName; const AOptions: TPOptions; AData: Pointer; DataSize: Integer): Integer;
begin
  Result := Add(AName, vtBinary, AOptions, IntToStrA(Cardinal(AData)), IntToStrA(DataSize));
end;

procedure TProperties.AddSetProperty(const Name: TPropertyName; Value, VisibleMembers: TSet32; ValuesEnum: TAnsiStringArray; const ADescription: AnsiString);
var i: Integer; s: AnsiString; EmptySet: Boolean;
begin
  s := '[';
  EmptySet := True;

  for i := 0 to High(ValuesEnum) do
    if (VisibleMembers = []) or (i in VisibleMembers) then begin
      Add(Name + '\' + ValuesEnum[i], vtBoolean, [], OnOffStr[i in Value], '');
      if i in Value then begin
        if not EmptySet then s := s + ', ';
        s := s + ValuesEnum[i];
        EmptySet := False;
      end;
    end;
  s := s + ']';
  Add(Name, vtString, [poReadonly], s, ADescription);
end;

function TProperties.SetSetProperty(const Name: TPropertyName; var Res: TSet32; ValuesEnum: TAnsiStringArray): Boolean;
var i: Integer; NewSet: TSet32;
begin
  NewSet := Res;
  for i := 0 to High(ValuesEnum) do
    if Valid(Name + '\' + ValuesEnum[i]) then
      if GetAsInteger(Name + '\' + ValuesEnum[i]) > 0 then
        Include(NewSet, i) else
          Exclude(NewSet, i);

  Result := NewSet <> Res;
  if Result then Res := NewSet;
end;

procedure TProperties.AddSetProperty(const Name: TPropertyName; Value, VisibleMembers: TSet32; const ValuesEnum, ADescription: TPropertyValue);
var Enum: TAnsiStringArray;
begin
  BaseStr.SplitA(ValuesEnum, StringDelimiter, Enum, True);
  AddSetProperty(Name, Value, VisibleMembers, Enum, ADescription);
  Enum := nil;
end;

function TProperties.SetSetProperty(const Name: TPropertyName; var Res: TSet32; const ValuesEnum: TPropertyValue): Boolean;
var Enum: TAnsiStringArray;
begin
  BaseStr.SplitA(ValuesEnum, StringDelimiter, Enum, True);
  Result := SetSetProperty(Name, Res, Enum);
  Enum := nil;
end;

function TProperties.GetIndex(const Name: AnsiString): Integer;
// Returns index of named property
begin
  for Result := 0 to FTotalProperties - 1 do if Name = Properties[Result].Name then Exit;
  Result := -1;
end;

function TProperties.GetValueByIndex(Index: Integer): AnsiString;
begin
  Assert((Index >= 0) and (Index < FTotalProperties), ClassName + '.GetValueByIndex: Invalid property index: ' + IntToStr(Index));
  Result := Properties[Index].Value;
end;

procedure TProperties.SetValueByIndex(Index: Integer; const Value: AnsiString);
begin
  if Index > -1 then begin
    Properties[Index].Value := Value;
    Changed := True;
  end;
end;

function TProperties.SetValue(const Name, Value: AnsiString): Integer;
// Puts property with given name in OProperty
// Returns: 0 if OK; -1 if no property found
begin
  Result := GetIndex(Name);
  SetValueByIndex(Result, Value);
end;

function TProperties.ValueToInteger(ValueType: Integer; const Value, Enumeration: AnsiString): Int32;
var Enums: TAnsiStringArray; TotalEnums: Int32; Val64: Int64;
begin
  case ValueType of
    vtNat, vtBinary, vtSingleSample, vtGradientSample: begin
      Val64 := StrToInt64Def(Value, 0);
       if (Val64 < 0) or (Val64 > MaxNat32) then Log(ClassName + '.ValueToInteger: Unsigned integer property out of range: ' + Value, lkWarning); 
      Result := Int32(Nat32(Val64 and $FFFFFFFF));
    end;
    vtInt: begin
      Val64 := StrToInt64Def(Value, 0);
       if (Val64 < MinInt32) or (Val64 > MaxInt32) then Log(ClassName + '.ValueToInteger: Integer property out of range: ' + Value, lkWarning); 
      Result := Int32(Nat32(Val64 and $FFFFFFFF));
    end;
    vtSingle,
    vtDouble:     Result := Trunc(0.5 + StrToFloatDef(Value, 0));
    vtString:     Result := StrToIntDef(Value, 0);
    vtObjectLink: Result := Ord(Value <> '');
    vtColor:      Result := Integer(Nat32(ColorStrToIntDef(Value, $80808080)));
    vtBoolean:    Result := Ord(Value = OnOffStr[True]);
    vtEnumerated: begin
      TotalEnums := SplitA(Enumeration, StringDelimiter, Enums, True);
      Result := TotalEnums-1;
      while (Result >= 0) and (Enums[Result] <> Value) do Dec(Result);
      Enums := nil;
    end;
    else begin
      Result := 0;
      Assert(False, 'Invalid property type');
    end;
  end;
end;

function TProperties.ValueToFloat(const Value: AnsiString): Extended;
begin
  Result := StrToFloatDef(Value, 0);
end;

procedure TProperties.SetEnumeratedValueByIndex(Index, ValueIndex: Integer);
var Enums: TAnsiStringArray; TotalEnums: Integer;
begin
  Properties[Index].Value := '-1';                              // "-1" is value for invalid enumerations or in case of invalid index
  if Properties[Index].Enumeration <> '' then begin
    TotalEnums := SplitA(Properties[Index].Enumeration, StringDelimiter, Enums, True);
    if ValueIndex < TotalEnums then Properties[Index].Value := Enums[ValueIndex];
    Enums := nil;
  end;
end;

function TProperties.GetAsXML: AnsiString;
// Returns string which represents properties in following format:
// <Properties>
// [<Group Name = "-Name-">]
// <Property Name = "-Name-" Type = "-ValueType-" Options = "-Options-">-Value-</Property>
// [</Group>]
// </Properties>
const IndentStr: array[0..1] of AnsiChar = ''; ReturnStr: array[0..1] of AnsiChar = #13#10;
var i: Integer; Indent: AnsiString;
begin
  Result := AnsiString('<Properties>') + ReturnStr;
  Indent := IndentStr;
  for i := 0 to FTotalProperties - 1 do begin
{    if Properties[i].ValueType = vtGroupBegin then begin
      Result := Result + Indent + '<Group Name = "' + Properties[i].Name + '">' + ReturnStr;
      Indent := Indent + IndentStr;
    end else if Properties[i].ValueType = vtGroupEnd then begin
      Result := Result + Indent + '</Group>' + ReturnStr;
      Indent := Copy(Indent, 1, Length(Indent)-Length(IndentStr));
    end else}
     Result := Result + Indent + '<Property Name = "' + Properties[i].Name + '"' +
                                 ' Type = "' + GetTypeAsString(Properties[i].ValueType) + '"' +
                                 ' Options = "' + PropertyOptionsToString(Properties[i].Options) + '"' +
                        '>' + GetValueByIndex(i) + '</Property>' + ReturnStr;
  end;
  Result := Result + '</Properties>';
end;

function TProperties.IsBinary(ValueType: TValueType): Boolean;
begin
  Result := (ValueType = vtBinary) or (ValueType = vtSingleSample) or (ValueType = vtGradientSample); 
end;

procedure TProperties.SetValueProc(const Name: TPropertyName; const Value: TPropertyValue);
begin
  SetValue(Name, Value);
end;

function TProperties.Write(Stream: TStream): Boolean;
var
  i, DataSize, TotalProps: Integer;
  IData: Int32;
  Data: Pointer; SData: Single; DData: Double;
begin
  TotalProps := 0;
  for i := 0 to FTotalProperties-1 do if not (poDerivative in Properties[i].Options) then Inc(TotalProps);
  Result := Stream.WriteCheck(PropertiesFileSignature, SizeOf(PropertiesFileSignature)) and
            Stream.WriteCheck(TotalProps, SizeOf(TotalProps));
// Save properties
  for i := 0 to FTotalProperties-1 do if not (poDerivative in Properties[i].Options) then begin
    Result := Result and
              Stream.WriteCheck(Properties[i].ValueType, SizeOf(Properties[i].ValueType)) and
              Stream.WriteCheck(Properties[i].Options,   SizeOf(Properties[i].Options))   and
              SaveString(Stream, Properties[i].Name);
    case Properties[i].ValueType of
      vtNat, vtInt, vtColor, vtBoolean, vtEnumerated: begin
        IData := ValueToInteger(Properties[i].ValueType, Properties[i].Value, Properties[i].Enumeration);
        Result := Result and Stream.WriteCheck(IData, SizeOf(IData));
      end;
      vtSingle: begin
        SData := ValueToFloat(Properties[i].Value);
        Result := Result and Stream.WriteCheck(SData, SizeOf(SData));
      end;
      vtDouble: begin
        DData := ValueToFloat(Properties[i].Value);
        Result := Result and Stream.WriteCheck(DData, SizeOf(DData));
      end;
      vtString, vtObjectLink: Result := Result and SaveString(Stream, Properties[i].Value);
      vtBinary, vtSingleSample, vtGradientSample: begin
        Data     := Pointer(StrToInt(Properties[i].Value));
        DataSize := StrToInt(Properties[i].Enumeration);
        Result := Result and
                  Stream.WriteCheck(DataSize, SizeOf(DataSize)) and
                  Stream.WriteCheck(Data^, DataSize);
      end;
      else Assert(False, 'Invalid property type');
    end;
    Result := Result and
              SaveString(Stream, Properties[i].Enumeration) and
              SaveString(Stream, Properties[i].Description);
  end;
end;

function TProperties.Read(Stream: TStream): Boolean;
var
  Sign: TFileSignature; i, DataSize: Integer;
  IData: Integer; Data: Pointer; SData: Single; DData: Double;
begin
  Result := False;

  if not Stream.ReadCheck(Sign, SizeOf(PropertiesFileSignature)) then Exit;

  if Sign <> PropertiesFileSignature then
    if not ErrorHandler(TInvalidFormat.Create('Invalid property signature')) then Exit;
// Load properties
  Clear;
  if not Stream.ReadCheck(FTotalProperties, SizeOf(FTotalProperties)) then Exit;
  SetLength(Properties, FTotalProperties);
  for i := 0 to FTotalProperties-1 do begin
    if not ( Stream.ReadCheck(Properties[i].ValueType, SizeOf(Properties[i].ValueType)) and
             Stream.ReadCheck(Properties[i].Options,   SizeOf(Properties[i].Options))   and
             LoadString(Stream, Properties[i].Name) ) then Exit;
    {$IFDEF COMPATMODE}
    if Properties[i].ValueType = vtBinary then begin
      if not Stream.ReadCheck(DataSize, SizeOf(DataSize)) then Exit;
      GetMem(Data, DataSize); ??
      if not Stream.ReadCheck(Data^, DataSize) then Exit;
      Properties[i].Value       := IntToStr(Cardinal(Data));
      Properties[i].Enumeration := IntToStr(DataSize);
    end else if not LoadString(Stream, Properties[i].Value) then Exit;
    {$ELSE}
    case Properties[i].ValueType of
      vtNat, vtInt, vtColor, vtBoolean, vtEnumerated: begin
        if not Stream.ReadCheck(IData, SizeOf(IData)) then Exit;
        case Properties[i].ValueType of
          vtNat:     Properties[i].Value := IntToStrA(Cardinal(IData));
          vtInt:     Properties[i].Value := IntToStrA(IData);
          vtColor:   Properties[i].Value := '#' + IntToHexA(Nat32(IData), 8);
          vtBoolean: Properties[i].Value := OnOffStr[IData <> 0];
        end;
      end;
      vtSingle: begin
        if not Stream.ReadCheck(SData, SizeOf(SData)) then Exit;
        Properties[i].Value := FloatToStrA(SData);
      end;
      vtDouble: begin
        if not Stream.ReadCheck(DData, SizeOf(DData)) then Exit;
        Properties[i].Value := FloatToStrA(DData);
      end;
      vtString, vtObjectLink: if not LoadString(Stream, Properties[i].Value) then Exit;
      vtBinary, vtSingleSample, vtGradientSample: begin
        if not Stream.ReadCheck(DataSize, SizeOf(DataSize)) then Exit;
        if DataSize > 0 then begin
          Data := TempCopy(nil, DataSize);
//          GetMem(Data, DataSize);                                        // Application should free this memory by itself or use @Link(RetrieveBinPropertyData)
          if not Stream.ReadCheck(Data^, DataSize) then Exit;
        end else
          Data := nil;

        Properties[i].Value       := IntToStrA(Cardinal(Data));
        Properties[i].Enumeration := IntToStrA(DataSize);
      end;
      else Assert(False, 'Invalid property type');
    end;
    {$ENDIF}

    if not ( LoadString(Stream, Properties[i].Enumeration) and
             LoadString(Stream, Properties[i].Description) ) then Exit;
    {$IFNDEF COMPATMODE}
    if Properties[i].ValueType = vtEnumerated then SetEnumeratedValueByIndex(i, IData);
    {$ENDIF}
  end;
  Result := True;
end;

(*function TProperties.Read(Stream: TStream): Boolean;
var Sign: TFileSignature; i, DataSize: Integer; Data: Pointer;
begin
  Result := False;

  if not Stream.ReadCheck(Sign, SizeOf(PropertiesFileSignature)) then Exit;

  if Sign <> PropertiesFileSignature then raise EInvalidFormat.Create('Invalid property signature');
// Load properties
  Clear;
  if not Stream.ReadCheck(FTotalProperties, SizeOf(FTotalProperties)) then Exit;
  SetLength(Properties, FTotalProperties);
  for i := 0 to FTotalProperties-1 do begin
    if not ( Stream.ReadCheck(Properties[i].ValueType, SizeOf(Properties[i].ValueType)) and
             Stream.ReadCheck(Properties[i].Options,   SizeOf(Properties[i].Options))   and
             LoadString(Stream, Properties[i].Name) ) then Exit;

    if Properties[i].ValueType = vtBinary then begin
      if not Stream.ReadCheck(DataSize, SizeOf(DataSize)) then Exit;
      GetMem(Data, DataSize);
      if not Stream.ReadCheck(Data^, DataSize) then Exit;
      Properties[i].Value       := IntToStr(Cardinal(Data));
      Properties[i].Enumeration := IntToStr(DataSize);
    end else if not LoadString(Stream, Properties[i].Value) then Exit;

    if not ( LoadString(Stream, Properties[i].Enumeration) and
             LoadString(Stream, Properties[i].Description) ) then Exit;
  end;
  Result := True;
end;*)

function TProperties.GetTempIndex(Data: Pointer): Integer;
begin
  Result := High(FTempBuffers);
  while (Result >= 0) and (FTempBuffers[Result] <> Data) do Dec(Result);
end;

procedure TProperties.AcquireData(Data: Pointer);
var i: Integer;
begin
  i := GetTempIndex(Data);
  if i >= 0 then FTempBuffers[i] := nil;
end;

function TProperties.TempCopy(Src: Pointer; Size: Integer): Pointer;
var i: Integer;
begin
  i := 0;
  while (i < Length(FTempBuffers)) and Assigned(FTempBuffers[i]) do Inc(i);
  if i >= Length(FTempBuffers) then SetLength(FTempBuffers, i+1);
  GetMem(FTempBuffers[i], Size);
  if Src <> nil then Move(Src^, FTempBuffers[i]^, Size);
  Result := FTempBuffers[i];
end;

function TProperties.FindAndFreeTemp(Data: Pointer): Boolean;
var i: Integer;
begin
  i := GetTempIndex(Data);
  if i >= 0 then begin
    FreeMem(FTempBuffers[i]);
    FTempBuffers[i] := nil;
  end;
  Result := i >= 0;
end;

procedure TProperties.Clear;
var i: Integer;
begin
  for i := 0 to FTotalProperties-1 do begin
    Properties[i].Name        := '';
    Properties[i].Value       := '';
    Properties[i].Enumeration := '';
    Properties[i].Description := '';
  end;
  SetLength(Properties, 0); FTotalProperties := 0;
  for i := 0 to High(FTempBuffers) do if Assigned(FTempBuffers[i]) then begin
    FreeMem(FTempBuffers[i]);
    FTempBuffers[i] := nil;
  end;
  Changed := True;
end;

constructor TProperties.Create;
begin
end;

constructor TProperties.Create(const jsonStr: TJSONString);
var J: TJSON;
begin
  J := TJSON.Create(jsonStr, JSONData);
  J.Free();
end;

destructor TProperties.Destroy;
begin
  Clear;
  inherited;
end;

{ TBaseFileConfig }

function TBaseFileConfig.Save: Boolean;
begin
  Result := SaveAs(FileName);
end;

function TBaseFileConfig.Load: Boolean;
begin
  Result := LoadFrom(FileName);
end;

constructor TBaseFileConfig.Create(const AFileName: BaseTypes.TFileName);
begin
  FileName := AFileName;
end;

constructor TBaseFileConfig.CreateFromFile(const AFileName: BaseTypes.TFileName);
begin
  Create(AFileName);
  Load;
end;

{ TFileConfig }

function TFileConfig.SaveAs(const AFilename: BaseTypes.TFileName): Boolean;
var cf: Text; i: Integer;
begin
  Result := True;
{$I-}
  Assign(cf, AFileName); Rewrite(cf);
  if IOResult <> 0 then begin
     Log(ClassName + '.SaveAs: Error opening file "' + FileName + '"', lkError); 
    Result := False;
    Exit;
  end;
  for i := 0 to FTotalProperties-1 do begin
    Writeln(cf, Properties[i].Name + '=' + Properties[i].Value);
    if IOResult <> 0 then begin
       Log(ClassName + '.SaveAs: Error writing to file "' + FileName + '"', lkError); 
      Result := False;
      Break;
    end;
  end;
  Close(cf);  
end;

function TFileConfig.LoadFrom(const AFilename: BaseTypes.TFileName): Boolean;
var cf: Text; s: AnsiString; SplitPos: Integer;
begin
  Result := True;
{$I-}
  Assign(cf, AFileName); Reset(cf);
  if IOResult <> 0 then begin
     Log(ClassName + '.LoadFrom: Error opening file "' + FileName + '"', lkError); 
    Result := False;
    Exit;
  end;

  Clear;

  while not EOF(cf) do begin
    Readln(cf, s);
    if IOResult <> 0 then begin
       Log(ClassName + '.LoadFrom: Error reading from file "' + FileName + '"', lkError); 
      Result := False;
      Break;
    end;
    s := TrimSpacesA(s);

    SplitPos := Pos('=', s);

    Add(TrimSpacesA(Copy(s, 1, SplitPos-1)), vtString, [], TrimSpacesA(Copy(s, SplitPos+1, Length(s))), '', '');
  end;
  Close(cf);
  Changed := True;
end;

{ TNiceFileConfig }

const CommentChar = '##'; LineNumberSeparator = #9;

function TNiceFileConfig.GetIndex(const Name: AnsiString): Integer;
var i: Integer; s: AnsiString;
begin
  Result := -1;
  for i := 0 to FTotalProperties - 1 do begin
    s := TrimSpacesA(Copy(Properties[i].Name, Pos(LineNumberSeparator, Properties[i].Name) + 1, Length(Properties[i].Name)));
    if Name = s then begin
      Result := i; Exit;
    end;
  end;
end;

function TNiceFileConfig.GetNameByIndex(const Index: Integer): AnsiString;
begin
  Result := TrimSpacesA(Copy(inherited GetNameByIndex(Index), Pos(LineNumberSeparator, inherited GetNameByIndex(Index)) + 1, Length(inherited GetNameByIndex(Index))));
end;

function TNiceFileConfig.GetValueByIndex(Index: Integer): AnsiString;
begin
  Result := TrimSpacesA(inherited GetValueByIndex(Index));
end;

function TNiceFileConfig.SaveAs(const AFilename: BaseTypes.TFileName): Boolean;
var cf: Text; i, LineSepPos: Integer; s: AnsiString;
begin
  Result := True;
{$I-}
  Assign(cf, AFileName); Rewrite(cf);
  if IOResult <> 0 then begin
     Log(ClassName + '.SaveAs: Error opening file "' + FileName + '"', lkError); 
    Result := False;
    Exit;
  end;

  for i := 0 to FTotalProperties-1 do begin
    s := Properties[i].Name;
    LineSepPos := Pos(LineNumberSeparator, s);
    s := Copy(s, LineSepPos+1, Length(s));
    if s <> '' then s := s + '=';
    s := s + Properties[i].Value;
    if Properties[i].Description <> '' then s := s + Properties[i].Description;
    Writeln(cf, s);
    if IOResult <> 0 then begin
       Log(ClassName + '.SaveAs: Error writing to file "' + FileName + '"', lkError); 
      Result := False;
      Break;
    end;
  end;
  Close(cf);
end;

function TNiceFileConfig.LoadFrom(const AFilename: BaseTypes.TFileName): Boolean;
var cf: Text; s, Value: AnsiString; SplitPos, CommentPos, ValueType, Line: Integer;
begin
  Result := True;
{$I-}
  Assign(cf, AFileName); Reset(cf);
  if IOResult <> 0 then begin
     Log(ClassName + '.LoadFrom: Error opening file "' + FileName + '"', lkError); 
    Result := False;
    Exit;
  end;

  Clear;
  
  Line := 1;
  while not EOF(cf) do begin
    Readln(cf, s);
    if IOResult <> 0 then begin
       Log(ClassName + '.LoadFrom: Error reading from file "' + FileName + '"', lkError); 
      Result := False;
      Break;
    end;

    CommentPos := Pos(CommentChar, s);
    if CommentPos = 0 then CommentPos := Length(s)+1;

    SplitPos := Pos('=', s);
    Value := Copy(s, SplitPos+1, CommentPos - SplitPos - 1);

    if isColor(Value) then ValueType := vtColor else
      if (TrimSpaces(Value) = OnOffStr[False]) or (TrimSpaces(Value) = OnOffStr[True]) then
        ValueType := vtBoolean else
          ValueType := vtString;

    Add(IntToStrA(Line) + LineNumberSeparator + Copy(s, 1, SplitPos-1), ValueType, [], Value, '', Copy(s, CommentPos + Length(CommentChar)-1, Length(s)));
    Inc(Line);
  end;
  Close(cf);
  Changed := True;
end;

end.



