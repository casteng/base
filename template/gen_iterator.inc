(*
*)
{$IFNDEF _ITERATOR_IMPLEMENTATION}
//  function HasNext(): Boolean;
  //function Next(): _IteratorValueType;
  function GetValue(const Index: NativeInt): _VectorValueType;
  procedure SetValue(const Index: NativeInt; const Value: _VectorValueType);

  function Add(const Value: _IteratorValueType): NativeInt;
  // Values retrieved by index
  property Values[const Index: NativeInt]: _VectorValueType read GetValue write SetValue; default;

  {$DEFINE _ITERATOR_IMPLEMENTATION}
{$ELSE}
  function _GenIterator.HasNext(): Boolean;
  begin
  end;

  function _GenIterator.Next(): _IteratorValueType;
  begin
  end;

  {$UNDEF _ITERATOR_IMPLEMENTATION}
{$ENDIF}