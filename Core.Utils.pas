unit Core.Utils;

interface
uses
  System.Classes,
  System.SysUtils,
  System.JSON;

type
  TRequestParamsEnumerator = class;

  TRequestParam = record
    private
      FName: string;
      FValue: string;
    public
      constructor Create(AName, AValue: string); overload;

      property Name: string read FName;
      property Value: string read FValue;
  end;

  TRequestParams = record
    private type RequestPrivateArray = array of TRequestParam;

    private
      FValues: RequestPrivateArray;
      FCount: Integer;
      function GetParam(Index: Integer): TRequestParam;

    public
      procedure AddItem(AParamName, AParamValue: string);
      procedure RemoveItem(AParamIndex: Integer);

      function GetEnumerator: TRequestParamsEnumerator;
      function AsStringList: TStringList;
      function AsPayload: string;

      property Parameters[Index: Integer]:TRequestParam read GetParam; default;
      property Count: Integer read FCount;
  end;

function GenerateRequestURL(const AAPIPath: string; AParameters: TRequestParams): string;

implementation

{ TRequestParam }

constructor TRequestParam.Create(AName, AValue: string);
begin
  FName := AName;
  FValue := AValue;
end;

{ TRequestParams }

function TRequestParams.GetParam(Index: Integer): TRequestParam;
begin
  if (Length(FValues) = 0) or (Length(FValues) - 1 < Index) then
  begin
    raise ERangeError.Create('The provided index does not exist in the current list') at @TRequestParams.GetParam;
  end else
  begin
    Result := FValues[Index];
  end;
end;

procedure TRequestParams.AddItem(AParamName, AParamValue: string);
begin
  SetLength(FValues, Length(FValues) + 1);
  FCount := Length(FValues);

  FValues[Length(FValues) - 1] := TRequestParam.Create(AParamName, AParamValue);
end;

function TRequestParams.AsPayload: string;
var
  Parameter: TRequestParam;
  JSONObject: TJSONObject;
begin
  JSONObject := TJSONObject.Create;
  try
    for Parameter in FValues do
    begin

      JSONObject.AddPair(Parameter.Name, Parameter.Value);
      // Type check, then assign correctly within a json object string.
    end;
    Result := JSONObject.ToString;
  finally
    JSONObject.Free;
  end;
end;

function TRequestParams.AsStringList: TStringList;
var
  Parameter: TRequestParam;
begin
  Result := TStringList.Create;
  for Parameter in FValues do
  begin
    Result.Add(Parameter.Name + '=' + Parameter.Value);
  end;
end;

function TRequestParams.GetEnumerator: TRequestParamsEnumerator;
begin
  Result := TRequestParamsEnumerator.Create(Self);
end;

function TRequestParams.GetParam(Index: Integer): TRequestParam;
begin
  if (Length(FValues) = 0) or (Length(FValues) - 1 < Index) then
  begin
    raise ERangeError.Create('The provided index does not exist in the current list') at @TRequestParams.GetParam;
  end else
  begin
    Result := FValues[Index];
  end;
end;

procedure TRequestParams.RemoveItem(AParamIndex: Integer);
var
  ArrLength: Integer;
  SurplusElements: Integer;
begin
  ArrLength := Length(FValues);
  if (ArrLength > 0) and (AParamIndex < ArrLength) then
  begin
    // Frees dynamically allocated memory
    Finalize(FValues[AParamIndex]);

    // Elements that are to the right of the "hole". If it's 0,
    // it means we had deleted the last one element and there are 0 to the right.
    SurplusElements := ArrLength - AParamIndex;


    if SurplusElements > 0 then
    begin
      // Move signature: procedure Move(const Source; var Dest; Count: NativeInt);
      // It will move SizeOf(TRequestParam) * SurplusElements bytes to the starting position FValues[AParamIndex]
      // and it will fill the hole created when we finalize() that value before.
      Move(FValues[AParamIndex + 1], FValues[AParamIndex], SizeOf(TRequestParam)* SurplusElements);
    end;

    // By the docs: "Initialize simply zeros out the memory occupied by long strings"
    // https://docwiki.embarcadero.com/Libraries/Athens/en/System.Initialize
    // So we are, actually, cleaning that spot we won't use anymore.
    Initialize(FValues[ArrLength - 1]);
    SetLength(FValues, ArrLength - 1);

    FCount := ArrLength - 1;
  end else
  begin
    raise ERangeError.Create('The provided index does not exist in the current list') at @TRequestParams.GetParam;
  end;

end;

end.
