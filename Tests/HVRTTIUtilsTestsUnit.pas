unit HVRTTIUtilsTestsUnit;

interface

procedure Main;

implementation

uses
{$IFDEF TestInsight}
  TestInsight.DUnit,
{$ELSE}
  Forms,
  GUITestRunner,
  TextTestRunner,
{$ENDIF TestInsight}
  TestFramework;

procedure Main;
begin
{$IFDEF TestInsight}
  TestInsight.DUnit.RunRegisteredTests();
{$ELSE}
  Application.Initialize;
  if IsConsole then
    TextTestRunner.RunRegisteredTests
  else
    GUITestRunner.RunRegisteredTests;
{$ENDIF TestInsight}
end;

end.
