{$IFDEF _GEN_VALUETYPE_CNT_RESET}
  {$UNDEF _ValueTypeCnt_0}
{$ENDIF}

{$IFNDEF _ValueTypeCnt_0}
  _ValueType
  {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_0}{$ENDIF}
{$ELSE}
  {$IFNDEF _ValueTypeCnt_1}
    _ValueType_1
    {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_1}{$ENDIF}
  {$ELSE}
    {$IFNDEF _ValueTypeCnt_2}
      _ValueType_2
      {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_2}{$ENDIF}
    {$ELSE}
      {$IFNDEF _ValueTypeCnt_3}
        _ValueType_3
        {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_3}{$ENDIF}
      {$ELSE}
        {$IFNDEF _ValueTypeCnt_4}
          _ValueType_4
          {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_4}{$ENDIF}
        {$ELSE}
          {$IFNDEF _ValueTypeCnt_5}
            _ValueType_5
            {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_5}{$ENDIF}
          {$ELSE}
            {$IFNDEF _ValueTypeCnt_6}
              _ValueType_6
              {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_6}{$ENDIF}
            {$ELSE}
              {$IFNDEF _ValueTypeCnt_7}
                _ValueType_7
                {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_7}{$ENDIF}
              {$ELSE}
                {$IFNDEF _ValueTypeCnt_8}
                  _ValueType_8
                  {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_8}{$ENDIF}
                {$ELSE}
                  {$IFNDEF _ValueTypeCnt_9}
                    _ValueType_9
                    {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_9}{$ENDIF}
                  {$ELSE}
                    {$IFNDEF _ValueTypeCnt_10}
                      _ValueType_10
                      {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE}{$DEFINE _ValueTypeCnt_10}{$ENDIF}
                    {$ELSE}
                      {$INFO 'Too many data types'}
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

{$UNDEF _GEN_VALUETYPE_CNT_ADVANCE}
{$UNDEF _GEN_VALUETYPE_CNT_RESET}
