unit FMRunnerForm;

interface

uses
  Tester, Logger, BaseTypes,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Layouts, FMX.TreeView, FMX.ExtCtrls, FMX.Ani, FMX.Grid, FMX.Effects,
  FMX.Filter.Effects, FMX.Objects, FMX.Memo;


type
  // FireMonkey GUI test runner
  TFMTestRunner = class(TTestRunner)
  private
    FRunAllTests: Boolean;
  protected
    function DoRun(): Boolean; override;
    function IsTestEnabled(const ATest: TTest): Boolean; override;
    function HandleTestResult(const ATest: TTest; TestResult: TTestResult): Boolean; override;
    procedure HandleCreateSuite(Suite: TTestSuite); override;
    procedure HandleDestroySuite(Suite: TTestSuite); override;
  end;

  TFMRunnerForm = class(TForm)
    TestsTree: TTreeView;
    TestLog: TMemo;
    ButtonsPanel: TLayout;
    BtnRunChecked: TCornerButton;
    BtnBtnRunAll: TCornerButton;
    Info: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure TestsTreeClick(Sender: TObject);
    procedure TestsTreeKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure TestsTreeChange(Sender: TObject);
    procedure TestsTreeChangeCheck(Sender: TObject);
    procedure BtnBtnRunAllClick(Sender: TObject);
    procedure BtnRunCheckedClick(Sender: TObject);
  private
    Root: TTestLevel;
    procedure Init();
  end;

  TTestTreeItem = class(TTreeViewItem)
  protected
    FIndex: Integer;
  public
    constructor Create(AOwner: TComponent; const AIndex: Integer);
  end;

implementation

const
  StatusLabel: array[TTestResult] of string = ('?', '-', 'V', 'X', '!', '!');
  StatusColor: array[TTestResult] of TAlphaColor = ($FF808080, $FF808080, $FF80FF80, $FFFF0000, $FFFF0000, $FFFF0000);

var
  Form: TFMRunnerForm;
  Runner: TFMTestRunner;

{$R *.fmx}

{ TFMTestRunner }

function TFMTestRunner.DoRun(): Boolean;
begin
  Runner := Self;
  Application.Initialize;
  Application.CreateForm(TFMRunnerForm, Form);
  Application.Run;
end;

function TFMTestRunner.IsTestEnabled(const ATest: TTest): Boolean;

  function FindTestItem(Index: Integer): TTestTreeItem;
  var i: Integer;
  begin
    i := Form.TestsTree.GlobalCount-1;
    while (i >= 0) and
          ( not (Form.TestsTree.ItemByGlobalIndex(i) is TTestTreeItem) or (TTestTreeItem(Form.TestsTree.ItemByGlobalIndex(i)).FIndex <> Index) ) do Dec(i);
    if i >= 0 then
      Result := Form.TestsTree.ItemByGlobalIndex(i) as TTestTreeItem
    else
      Result := nil;
  end;

begin
  Result := FRunAllTests or ((FindTestItem(ATest.Index) <> nil) and FindTestItem(ATest.Index).IsChecked);
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
    trNone: s := s + ' not run';
    trDisabled: s := s + ' disabled';
    trSuccess: s := s + ' passed';
    trFail: s := s + ' failed ' + CodeLocToStr(ATest.FailCodeLoc);
    trException: s := s + ' exception';
    trError: s := s + ' error';
  end;

  Form.TestLog.Lines.Add(s);
end;

{ TFMRunnerForm }

procedure TFMRunnerForm.BtnBtnRunAllClick(Sender: TObject);
begin
  TestLog.Lines.Clear;
  Runner.FRunAllTests := True;
  Runner.TestRoot.Run(crcAlways);
end;

procedure TFMRunnerForm.BtnRunCheckedClick(Sender: TObject);
begin
  TestLog.Lines.Clear;
  Runner.FRunAllTests := False;
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
      Status.Parent := Item;
      Status.Text := StatusLabel[Level.Tests[i].LastResult];
      Status.Fill.Color := StatusColor[Level.Tests[i].LastResult];
      Status.Align := TAlignLayout.alRight;
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

procedure TFMRunnerForm.TestsTreeChange(Sender: TObject);
begin
  Log('On change' + Sender.ClassName);
end;

procedure TFMRunnerForm.TestsTreeChangeCheck(Sender: TObject);
begin
  Log('On change check ' + Sender.ClassName);
end;

procedure TFMRunnerForm.TestsTreeClick(Sender: TObject);
begin
  Log('On tree click' + Sender.ClassName);
end;

procedure TFMRunnerForm.TestsTreeKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  Log('On key up');
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


