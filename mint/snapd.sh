[ -f /etc/apt/preferences.d/nosnap.pref ] && sudo mv /etc/apt/preferences.d/nosnap.pref ~/Documents/nosnap.backup
sudo apt update
sudo apt -y install build-essential procps curl file git
sudo apt install snapd
sudo snap refresh
