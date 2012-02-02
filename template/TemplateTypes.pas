(*
  @Abstract(Template types unit)
  (C) 2011 George "Mirage" Bakhtadze.
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file
  Created: Jan 30, 2012
  The unit contains some template classes instantiations
*)
{$Include GDefines.inc}
unit TemplateTypes;

interface
  
  uses
    Template,
    tpl_integer, tpl_ansistring;

  type
    TIntegerVector = tpl_integer.TIntegerVector;

implementation

end.