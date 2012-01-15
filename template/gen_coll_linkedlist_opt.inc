(*
  Generic quicksort algorithm option constants
*)
  {$IF (dsRangeCheck in _LinkedListOptions)}
    {$DEFINE _RANGECHECK}
  {$ELSE}
    {$UNDEF _RANGECHECK}
  {$IFEND}
