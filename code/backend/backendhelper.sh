export PATH=~/.toast/armed/bin:$PATH
export LD_LIBRARY_PATH=~/.toast/armed/lib:$LD_LIBRARY_PATH
psql -h /home/doersino/tmp -f ../handwriting_setup.sql >/dev/null 2>&1
psql -h /home/doersino/tmp --variable=pen="$1" -f ../handwriting.sql 2>&1
exit 0
