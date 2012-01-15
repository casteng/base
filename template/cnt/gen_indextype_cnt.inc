{$IFDEF _GEN_INDEXTYPE_CNT_RESET}
  {$UNDEF _IndexTypeCnt_0}
{$ENDIF}

{$IFNDEF _IndexTypeCnt_0}
  _IndexType
  {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_0}{$ENDIF}
{$ELSE}
  {$IFNDEF _IndexTypeCnt_1}
    _IndexType_1
    {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_1}{$ENDIF}
  {$ELSE}
    {$IFNDEF _IndexTypeCnt_2}
      _IndexType_2
      {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_2}{$ENDIF}
    {$ELSE}
      {$IFNDEF _IndexTypeCnt_3}
        _IndexType_3
        {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_3}{$ENDIF}
      {$ELSE}
        {$IFNDEF _IndexTypeCnt_4}
          _IndexType_4
          {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_4}{$ENDIF}
        {$ELSE}
          {$IFNDEF _IndexTypeCnt_5}
            _IndexType_5
            {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_5}{$ENDIF}
          {$ELSE}
            {$IFNDEF _IndexTypeCnt_6}
              _IndexType_6
              {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_6}{$ENDIF}
            {$ELSE}
              {$IFNDEF _IndexTypeCnt_7}
                _IndexType_7
                {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_7}{$ENDIF}
              {$ELSE}
                {$IFNDEF _IndexTypeCnt_8}
                  _IndexType_8
                  {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_8}{$ENDIF}
                {$ELSE}
                  {$IFNDEF _IndexTypeCnt_9}
                    _IndexType_9
                    {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_9}{$ENDIF}
                  {$ELSE}
                    {$IFNDEF _IndexTypeCnt_10}
                      _IndexType_10
                      {$IFDEF _GEN_INDEXTYPE_CNT_ADVANCE}{$DEFINE _IndexTypeCnt_10}{$ENDIF}
                    {$ELSE}
                      {$INFO 'Too many data types'}
                      "Too many index types"
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

{$UNDEF _GEN_INDEXTYPE_CNT_ADVANCE}
{$UNDEF _GEN_INDEXTYPE_CNT_RESET}
