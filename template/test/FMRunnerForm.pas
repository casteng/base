(*
  @Abstract(FireMonkey test runner form unit)
  (C) 2003-2012 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  Created: Feb 20, 2012
  The unit contains FireMonkey test runner form
*)
unit FMRunnerForm;

interface

uses
  Tester, Logger, BaseTypes,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Layouts, FMX.TreeView, FMX.ExtCtrls, FMX.Ani, FMX.Grid, FMX.Effects,
  FMX.Filter.Effects, FMX.Objects, FMX.Memo;


type
  // Test enabled check delegate
  TTestEnabledFunc = function(const ATest: TTest): Boolean of object;

  // FireMonkey GUI test runner
  TFMTestRunner = class(TTestRunner)
  private
    procedure HandleException(Sender: TObject; E: Exception);
    function RunCheckedFunc(const ATest: TTest): Boolean;
    function RunSelectedFunc(const ATest: TTest): Boolean;
  protected
    FCheckFunc: TTestEnabledFunc;
    function DoRun(): Boolean; override;
    function IsTestEnabled(const ATest: TTest): Boolean; override;
    function HandleTestResult(const ATest: TTest; TestResult: TTestResult): Boolean; override;
    procedure HandleCreateSuite(Suite: TTestSuite); override;
    procedure HandleDestroySuite(Suite: TTestSuite); override;
  end;

  TTestTreeItem = class(TTreeViewItem)
  protected
    FIndex: Integer;
  public
    constructor Create(AOwner: TComponent; const AIndex: Integer);
  end;

  TFMRunnerForm = class(TForm)
    TestsTree: TTreeView;
    TestLog: TMemo;
    ButtonsPanel: TLayout;
    BtnRunChecked: TCornerButton;
    BtnBtnRunAll: TCornerButton;
    procedure FormCreate(Sender: TObject);
    procedure TestsTreeKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure TestsTreeChange(Sender: TObject);
    procedure TestsTreeChangeCheck(Sender: TObject);
    procedure BtnBtnRunAllClick(Sender: TObject);
    procedure BtnRunCheckedClick(Sender: TObject);
    procedure BtnRunSelectedClick(Sender: TObject);
    procedure TestsTreeDblClick(Sender: TObject);
  private
    Root: TTestLevel;
    procedure Init();
    function FindTestItem(Index: Integer): TTestTreeItem;
    procedure UpdateStatus(const Test: TTest);
  end;

implementation

const
  StatusLabel: array[TTestResult] of string = ('?', '---', '---', 'V', 'X', '!', '!');
  StatusColor: array[TTestResult] of TAlphaColor = ($FF606060, $FFA0A0A0, $FFA0A0A0, $FF40A040, $FFC00000, $FFFF0000, $FFFF0000);

var
  Form: TFMRunnerForm;
  Runner: TFMTestRunner;

{$R *.fmx}

{ TFMTestRunner }

procedure TFMTestRunner.HandleException(Sender: TObject; E: Exception);
begin
  Form.TestLog.Lines.Add('Exception: ' + e.ClassName);
end;

function TFMTestRunner.DoRun(): Boolean;
begin
  Runner := Self;
  Application.Initialize;
  Application.OnException := HandleException;
  Application.CreateForm(TFMRunnerForm, Form);
  Application.Run;
end;

function TFMTestRunner.IsTestEnabled(const ATest: TTest): Boolean;
begin
  Result := (@FCheckFunc = nil) or FCheckFunc(ATest);
end;

function TFMTestRunner.RunCheckedFunc(const ATest: TTest): Boolean;
begin
  Result := (Form.FindTestItem(ATest.Index) <> nil) and Form.FindTestItem(ATest.Index).IsChecked;
end;

function TFMTestRunner.RunSelectedFunc(const ATest: TTest): Boolean;

  function isChildOf(AItem, AParent: TTreeViewItem): Boolean;
  begin
    while (AItem is TTreeViewItem) and (AItem <> AParent) do AItem := AItem.ParentItem;
    Result := AItem = AParent;
  end;

var TreeItem: TTreeViewItem;
begin
  Result := False;
  TreeItem := Form.FindTestItem(ATest.Index);
  if TreeItem = nil then Exit;
  Result := (Form.TestsTree.Selected = TreeItem) or (TreeItem.IsChecked and isChildOf(TreeItem, Form.TestsTree.Selected));
end;

procedure TFMTestRunner.HandleCreateSuite(Suite: TTestSuite);
begin
  inherited;

end;

procedure TFMTestRunner.HandleDestroySuite(Suite: TTestSuite);
begin
  inherited;

end;

function TFMTestRunner.HandleTestResult(const ATest: TTest; TestResult: TTestResult): Boolean;
var s: string;
begin
  Result := not (TestResult in [trFail, trException, trError]);
  s := ATest.Suite.ClassName + '.' + ATest.Name;
  case TestResult of
    trNone:      s := s + ' not run';
    trDisabled:  s := s + ' disabled';
    trSkipped:   s := s + ' skipped';
    trSuccess:   s := s + ' passed';
    trFail:      s := s + ' failed ' + CodeLocToStr(ATest.FailCodeLoc);
    trException: s := s + ' exception';
    trError:     s := s + ' error';
  end;

  Form.TestLog.Lines.Add(s);
  Form.UpdateStatus(ATest);

  Application.ProcessMessages;                                // Update screen
end;

{ TFMRunnerForm }

procedure TFMRunnerForm.BtnBtnRunAllClick(Sender: TObject);
begin
  TestLog.Lines.Clear;
  Runner.FCheckFunc := nil;
  Runner.TestRoot.Run(crcAlways);
end;

procedure TFMRunnerForm.BtnRunCheckedClick(Sender: TObject);
begin
  TestLog.Lines.Clear;
  Runner.FCheckFunc := Runner.RunCheckedFunc;
  Runner.TestRoot.Run(crcAlways);
end;

procedure TFMRunnerForm.BtnRunSelectedClick(Sender: TObject);
begin
  TestLog.Lines.Clear;
  Runner.FCheckFunc := Runner.RunSelectedFunc;
  Runner.TestRoot.Run(crcAlways);
end;

procedure TFMRunnerForm.FormCreate(Sender: TObject);
begin
  Form.Init();
end;

procedure TFMRunnerForm.Init();

  function AddItem(Level: TTestLevel; Parent: TFmxObject): TTreeViewItem;
  var
    i: Integer;
    Item: TTreeViewItem;
    Status: TText;
  begin
    if Level = nil then Exit;
    Result := TTreeViewItem.Create(Self);
    Result.Text := Level.SuiteClass.ClassName;
    Result.Parent := Parent;
    Result.IsExpanded := True;
    for i := 0 to Level.TotalChilds-1 do AddItem(Level.Childs[i], Result);
    for i := 0 to Level.TotalTests-1 do begin
      Item := TTestTreeItem.Create(Self, Level.Tests[i].Index);
      Item.Parent := Result;
      Item.Text := Level.Tests[i].Name;
      Item.IsChecked := True;
      Status := TText.Create(Self);
      Status.BindingName := '_status';
      Status.Parent := Item;
      Status.Align := TAlignLayout.alRight;
      Status.Font.Style := [TFontStyle.fsBold];
      UpdateStatus(Level.Tests[i]);
    end;
  end;

begin
  TestsTree.BeginUpdate;
  try
    AddItem(Runner.TestRoot, TestsTree);
  finally
    TestsTree.EndUpdate;
  end;
  Log('Tree items: ' + IntToStr(TestsTree.Count), LLWarning);
end;

function TFMRunnerForm.FindTestItem(Index: Integer): TTestTreeItem;
var i: Integer;
begin
  i := TestsTree.GlobalCount-1;
  while (i >= 0) and
        ( not (TestsTree.ItemByGlobalIndex(i) is TTestTreeItem) or (TTestTreeItem(TestsTree.ItemByGlobalIndex(i)).FIndex <> Index) ) do Dec(i);
  if i >= 0 then
    Result := TestsTree.ItemByGlobalIndex(i) as TTestTreeItem
  else
    Result := nil;
end;

procedure TFMRunnerForm.UpdateStatus(const Test: TTest);
var
  TreeItem: TTestTreeItem;
  Status: TText;
begin
  TreeItem := FindTestItem(Test.Index);
  Assert(Assigned(TreeItem));

  Status := TreeItem.FindBinding('_status') as TText;
  Status.Text := StatusLabel[Test.LastResult];
  Status.Fill.Color := StatusColor[Test.LastResult];
end;

procedure TFMRunnerForm.TestsTreeChange(Sender: TObject);
begin
  Log('On change ' + Sender.ClassName);
end;

procedure SetChecked(Item: TTreeViewItem; AChecked: Boolean);
var i: Integer;
begin
  if Item = nil then Exit;
  Item.IsChecked := AChecked;
  for i := 0 to Item.Count-1 do SetChecked(Item.Items[i], AChecked);
end;

procedure SetCheckedPreserveSel(Tree: TTreeView; Item: TTreeViewItem; AChecked: Boolean);
var Selected: TTreeViewItem;
begin
  Tree.BeginUpdate;                   // Why selected is changing when isChecked modified??
  Selected := Tree.Selected;
  SetChecked(Item, AChecked);
  Tree.Selected := Selected;
  tree.EndUpdate;
end;

procedure TFMRunnerForm.TestsTreeChangeCheck(Sender: TObject);
begin
  SetCheckedPreserveSel(TestsTree, Sender as TTreeViewItem, (Sender as TTreeViewItem).IsChecked);
end;

procedure TFMRunnerForm.TestsTreeDblClick(Sender: TObject);
begin
  BtnRunSelectedClick(Sender);
end;

procedure TFMRunnerForm.TestsTreeKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  Log('On tree keyup ' + Sender.ClassName);
  if (Key = vkSpace) and (TestsTree.Selected <> nil) then
    TestsTree.Selected.IsChecked := not TestsTree.Selected.IsChecked;
    //SetChecked(TestsTree.Selected, not TestsTree.Selected.IsChecked);
end;

{ TTestTreeItem }

constructor TTestTreeItem.Create(AOwner: TComponent; const AIndex: Integer);
begin
  inherited Create(AOwner);
  FIndex := AIndex;
end;

initialization
  SetRunner(TFMTestRunner.Create());
end.


