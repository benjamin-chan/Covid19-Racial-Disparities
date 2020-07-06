call :executeR mungeData.R

exit /b


:executeR
REM to execute locally
set exe="C:\Users\or0250652\Documents\R\R-3.5.3\bin\x64\Rscript.exe"
set f=%1
%exe% %f%
