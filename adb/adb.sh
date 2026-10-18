# Termux
pkg update
pkg install microsocks
microsocks -i 0.0.0.0 -p 9030

# ADB
adb forward tcp:9030 tcp:9030
