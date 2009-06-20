unit frmArrayEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,ZExpressions, Grids, StdCtrls, ZClasses, ComCtrls;

type
  TArrayEditForm = class(TForm)
    Button1: TButton;
    Grid: TStringGrid;
    UpDown1: TUpDown;
    Dim3Edit: TEdit;
    procedure GridSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
    procedure UpDown1ChangingEx(Sender: TObject; var AllowChange: Boolean;
      NewValue: Smallint; Direction: TUpDownDirection);
  private
    { Private declarations }
    TheArray : TDefineArray;
    Index3 : integer;
    function ValueAsText(P : PFloat) : string;
    procedure SetValueFromText(const S: String; P: PFloat);
    procedure ReadFromArray;
  public
    { Public declarations }
    procedure SetArray(A : TDefineArray);
  end;

var
  ArrayEditForm: TArrayEditForm;

implementation

{$R *.dfm}

uses DesignerGUI;

{ TArrayEditForm }

procedure TArrayEditForm.GridSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
var
  P : PFloat;
  Index : integer;
begin
  P := TheArray.GetData;
  Index := 0;
  case TheArray.Dimensions of
    dadOne:
      begin
        Index := ACol-1;
      end;
    dadTwo:
      begin
        Index := ((ARow-1)*TheArray.SizeDim2) + (ACol-1);
      end;
    dadThree:
      begin
        Index := (Index3*TheArray.SizeDim2*TheArray.SizeDim3) + ((ARow-1)*TheArray.SizeDim3) + (ACol-1);
      end;
  end;
  Inc(P,Index);
  SetValueFromText(Value,P);
end;

procedure TArrayEditForm.SetArray(A: TDefineArray);
begin
  TheArray := A;

  Index3 := 0;
  Dim3Edit.Visible := A.Dimensions=dadThree;
  Dim3Edit.Text := '0';
  UpDown1.Visible := A.Dimensions=dadThree;
  if UpDown1.Visible then
    UpDown1.Max := A.SizeDim1-1;

  ReadFromArray;
end;

procedure TArrayEditForm.ReadFromArray;
var
  J: Integer;
  I: Integer;
  P: PFloat;
  A: TDefineArray;
begin
  A := Self.TheArray;
  case A.Dimensions of
    dadOne:
      begin
        Grid.RowCount := 2;
        Grid.ColCount := A.SizeDim1 + 1;
        for I := 0 to A.SizeDim1 - 1 do
          Grid.Cells[I + 1, 0] := IntToStr(I);
        P := A.GetData;
        for I := 0 to A.SizeDim1 - 1 do
        begin
          Grid.Cells[I + 1, 1] := ValueAsText(P);
          Inc(P);
        end;
      end;
    dadTwo:
      begin
        Grid.RowCount := A.SizeDim1 + 1;
        Grid.ColCount := A.SizeDim2 + 1;
        P := A.GetData;
        for I := 0 to A.SizeDim1 - 1 do
          Grid.Cells[0, I + 1] := IntToStr(I);
        for J := 0 to A.SizeDim2 - 1 do
          Grid.Cells[J + 1, 0] := IntToStr(J);
        for I := 0 to A.SizeDim1 - 1 do
        begin
          for J := 0 to A.SizeDim2 - 1 do
          begin
            Grid.Cells[J + 1, I + 1] := ValueAsText(P);
            Inc(P);
          end;
        end;
      end;
    dadThree:
      begin
        Grid.RowCount := A.SizeDim2 + 1;
        Grid.ColCount := A.SizeDim3 + 1;
        P := A.GetData;
        for I := 0 to A.SizeDim2 - 1 do
          Grid.Cells[0, I + 1] := IntToStr(I);
        for J := 0 to A.SizeDim3 - 1 do
          Grid.Cells[J + 1, 0] := IntToStr(J);
        Inc(P,Self.Index3*A.SizeDim2*A.SizeDim3);
        for I := 0 to A.SizeDim2 - 1 do
        begin
          for J := 0 to A.SizeDim3 - 1 do
          begin
            Grid.Cells[J + 1, I + 1] := ValueAsText(P);
            Inc(P);
          end;
        end;
      end;
  end;
end;

function TArrayEditForm.ValueAsText(P: PFloat): string;
begin
  case TheArray._Type of
    dvbFloat: Result := DesignerFormatFloat(P^);
    dvbInt: Result := IntToStr(PInteger(P)^);
  end;
end;

procedure TArrayEditForm.SetValueFromText(const S : String; P: PFloat);
begin
  case TheArray._Type of
    dvbFloat: P^ := StrToFloatDef(S,0);
    dvbInt: PInteger(P)^ := StrToIntDef(S,0);
  end;
end;

procedure TArrayEditForm.UpDown1ChangingEx(Sender: TObject;
  var AllowChange: Boolean; NewValue: Smallint; Direction: TUpDownDirection);
begin
  if (NewValue>=0) and (NewValue<TheArray.SizeDim1) then
  begin
    Index3 := NewValue;
    ReadFromArray;
  end
  else
    AllowChange := False;
end;

end.
