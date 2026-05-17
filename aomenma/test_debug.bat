@echo off
cd /d "%~dp0"
echo Starting > run.log
echo STEP 1: cd done >> run.log
where py > run_py.log 2>&1
echo STEP 2: py check done >> run.log
start /B py -3 server\proxy.py > proxy.log 2>&1
echo STEP 3: proxy launched >> run.log
timeout /t 5 /nobreak >/dev/null
echo STEP 4: waited 5s >> run.log
curl -s http://localhost:3002/ >> run.log 2>&1
echo STEP 5: curl done >> run.log
echo ====== DONE ======
pause
