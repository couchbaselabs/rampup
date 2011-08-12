@echo off
echo usage : runtest couchbase*.rpm NUM_ITEMS MEMBASE_NUM_VBUCKETS [EXTRA_SLEEP]

echo       : runtest $1 $2 $3

echo # start - runtest $1 $2 $3 
echo %date%-%time% 

set NS_BIN=%~dp0
set NS_ROOT=%NS_BIN%..
set NS_ERTS=%NS_ROOT%\erts-5.8.4\bin


REM cleanup previous run
cmd /C service_stop.bat
cmd /C service_unregister.bat
echo y | DEL /s %NS_ROOT%\var\lib\membase\config\config.dat
echo y | DEL /s %NS_ROOT%\var\lib\membase\mnesia\*
echo y | DEL /s %NS_ROOT%\var\lib\membase\data\default\*
echo y | DEL /s %NS_ROOT%\var\lib\membase\data\.default\*

REM restart couchbase server
setx MEMBASE_NUM_VBUCKETS 4 /M
cmd /C service_register.bat
cmd /C service_start.bat
sleep 5

membase cluster-init -c 127.0.0.1 --cluster-init-username=Administrator --cluster-init-password=password

membase bucket-create -c 127.0.0.1 -u Administrator -p password --bucket=default --bucket-type=membase --bucket-ramsize=3000 --bucket-replica=0 --bucket-password=
sleep 4

curl -vX PUT http://127.0.0.1:5984/default/_design/rampup -d @rampup.json
echo # loading membase...
echo %date%-%time% 
pslist | grep erl

set DRIVE_HOST=127.0.0.1
set RATIO_SETS=1.0
set RATIO_CREATES=1.0
set MAX_CREATES=10000
set EXIT_AFTER_CREATES=1
"%NS_ERTS%\erl.exe" -eval "rampup:drive_test(), init:stop()."

echo # using membase...
echo %date%-%time% 
pslist | grep erl
set DRIVE_HOST=127.0.0.1
set RATIO_SETS=0.0
set MAX_OPS=10000
"%NS_ERTS%\erl.exe" -eval "rampup:drive_test(), init:stop()."

echo # view building...
echo %date%-%time%
pslist | grep erl

curl http://127.0.0.1:5984/default/_design/rampup/_view/random?limit=10&

echo # view accessing...
echo %date%-%time%
pslist | grep erl

rampup-view.rb "127.0.0.1" 1000

echo # done -
echo %date%-%time%
@echo on
