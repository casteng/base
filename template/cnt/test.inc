{$IFDEF _GEN_VALUETYPE_CNT_RESET}
  {$UNDEF _valueTypeCnt_0}
{$ENDIF}

{$IFNDEF _valueTypeCnt_0}
  _ValueType
  {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_0} {$ENDIF}
{$ELSE}
  {$IFNDEF _valueTypeCnt_1}
    _ValueType_1
    {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_1} {$ENDIF}
  {$ELSE}
    {$IFNDEF _valueTypeCnt_2}
      _ValueType_2
      {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_2} {$ENDIF}
    {$ELSE}
      {$IFNDEF _valueTypeCnt_3}
        _ValueType_3
        {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_3} {$ENDIF}
      {$ELSE}
        {$IFNDEF _valueTypeCnt_4}
          _ValueType_4
          {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_4} {$ENDIF}
        {$ELSE}
          {$IFNDEF _valueTypeCnt_5}
            _ValueType_5
            {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_5} {$ENDIF}
          {$ELSE}
            {$IFNDEF _valueTypeCnt_6}
              _ValueType_6
              {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_6} {$ENDIF}
            {$ELSE}
              {$IFNDEF _valueTypeCnt_7}
                _ValueType_7
                {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_7} {$ENDIF}
              {$ELSE}
                {$IFNDEF _valueTypeCnt_8}
                  _ValueType_8
                  {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_8} {$ENDIF}
                {$ELSE}
                  {$IFNDEF _valueTypeCnt_9}
                    _ValueType_9
                    {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_9} {$ENDIF}
                  {$ELSE}
                    {$IFNDEF _valueTypeCnt_10}
                      _ValueType_10
                      {$IFDEF _GEN_VALUETYPE_CNT_ADVANCE} {$DEFINE _valueTypeCnt_10} {$ENDIF}
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
