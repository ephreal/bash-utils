#sudo echo "Starting jack"
#sudo jackd -r -d dummy -r 48000 &
#sleep 5
echo "Starting audio bridge for midi passthrough to lmms"
a2j_control --ehw && a2j_control --start
