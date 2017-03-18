program HVRTTIUtilsTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options 
  to use the console test runner.  Otherwise the GUI test runner will be used by 
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  TestFramework,
{$IFDEF TestInsight}
  TestInsight.DUnit,
{$ELSE}
  Forms,
  GUITestRunner,
  TextTestRunner,
{$ENDIF TestInsight}
  HVVMT in '..\HVVMT.pas',
  VmtTestsUnit in 'VmtTestsUnit.pas';

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
end.
