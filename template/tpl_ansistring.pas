(*
  @Abstract(Ansi string template instantiations unit)
  (C) 2011 George "Mirage" Bakhtadze.
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file
  Created: Jan 30, 2012
  The unit contains ansi string template instantiations
*)
{$Include GDefines.inc}
unit tpl_ansistring;

interface

  uses Template;

  type
    tpl_type = AnsiString;

    _VectorValueType = tpl_type;
    {$IFDEF TPL_HINTS}{$MESSAGE 'Instantiating TIntegerVector interface'}{$ENDIF}
    {$I gen_coll_vector.inc}
    _LinkedListValueType = tpl_type;
    {$IFDEF TPL_HINTS}{$MESSAGE 'Instantiating TIntegerLinkedList interface'}{$ENDIF}
    {$I gen_coll_linkedlist.inc}


    TAnsiStringVector = _GenVector;
    TAnsiStringLinkedList = _GenLinkedList;

implementation

  {$IFDEF TPL_HINTS}{$MESSAGE 'Instantiating TIntegerVector'}{$ENDIF}
  {$I gen_coll_vector.inc}

  {$IFDEF TPL_HINTS}{$MESSAGE 'Instantiating TIntegerLinkedList'}{$ENDIF}
  {$I gen_coll_linkedlist.inc}

end.
