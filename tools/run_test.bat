::========================================================================================
call clean.bat
::========================================================================================
call build.bat
::========================================================================================
cd ../sim
:: pentru gui
:: vsim -gui -do run.do
:: pentru terminal
:: vsim -c   -do run.do 

:: sa apelam scriptul cu argumente
vsim -%5 -do "do run.do %1 %2 %3 %4 %6 %7"
cd ../tools
