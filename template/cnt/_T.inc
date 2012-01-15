{$IF not Declared(_ValueType_0)}
  {$UNDEF _ValueType_0}
{$IFEND}

{$IFNDEF _ValueType_0}
  _ValueType_0
  {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_0}{$ENDIF}
{$ELSE}
  {$IFNDEF _ValueType_1}
    _ValueType_1
    {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_1}{$ENDIF}
  {$ELSE}
    {$IFNDEF _ValueType_2}
      _ValueType_2
      {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_2}{$ENDIF}
    {$ELSE}
      {$IFNDEF _ValueType_3}
        _ValueType_3
        {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_3}{$ENDIF}
      {$ELSE}
        {$IFNDEF _ValueType_4}
          _ValueType_4
          {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_4}{$ENDIF}
        {$ELSE}
          {$IFNDEF _ValueType_5}
            _ValueType_5
            {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_5}{$ENDIF}
          {$ELSE}
            {$IFNDEF _ValueType_6}
              _ValueType_6
              {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_6}{$ENDIF}
            {$ELSE}
              {$IFNDEF _ValueType_7}
                _ValueType_7
                {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_7}{$ENDIF}
              {$ELSE}
                {$IFNDEF _ValueType_8}
                  _ValueType_8
                  {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_8}{$ENDIF}
                {$ELSE}
                  {$IFNDEF _ValueType_9}
                    _ValueType_9
                    {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_9}{$ENDIF}
                  {$ELSE}
                    {$IFNDEF _ValueType_10}
                      _ValueType_10
                      {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_10}{$ENDIF}
                    {$ELSE}
                      {$ERROR 'Too many data types'}
                      "Too many value types"
                    {$ENDIF}
                  {$ENDIF}
                {$ENDIF}
              {$ENDIF}
            {$ENDIF}
          {$ENDIF}
        {$ENDIF}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$UNDEF _GEN_CNT_ADV}
