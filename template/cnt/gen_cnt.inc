(*
  Compile time counter
  (C) George Bakhtadze
*)
{$IFDEF _GEN_COUNTER_RESET}
  {$UNDEF _gen_counter0}
{$ENDIF}

{$IFNDEF _gen_counter0}_
  {$IFDEF _GEN_COUNTER_ADVANCE} {$DEFINE _gen_counter0} {$ENDIF}
{$ELSE}
  {$IFNDEF _gen_counter1}
    _1
    {$IFDEF _GEN_COUNTER_ADVANCE} {$DEFINE _gen_counter1} {$ENDIF}
  {$ELSE}
    {$IFNDEF _gen_counter2}
      _2
      {$IFDEF _GEN_COUNTER_ADVANCE} {$DEFINE _gen_counter2} {$ENDIF}
    {$ELSE}
      {$IFNDEF _gen_counter3}
        _3
        {$IFDEF _GEN_COUNTER_ADVANCE} {$DEFINE _gen_counter3} {$ENDIF}
      {$ELSE}
        {$IFNDEF _gen_counter4}
          _4
          {$IFDEF _GEN_COUNTER_ADVANCE} {$DEFINE _gen_counter4} {$ENDIF}
        {$ELSE}
          {$IFNDEF _gen_counter5}
            _5
            {$IFDEF _GEN_COUNTER_ADVANCE} {$DEFINE _gen_counter5} {$ENDIF}
          {$ELSE}

          {$ENDIF}
        {$ENDIF}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$UNDEF _GEN_COUNTER_ADVANCE}
{$UNDEF _GEN_COUNTER_RESET}
