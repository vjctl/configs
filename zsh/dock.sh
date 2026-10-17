# Apple Dock configuration script
# Run this to add a spacer tile to the Dock and restart it

defaults write com.apple.dock persistent-apps -array-add '{tile-data={}; tile-type="spacer-tile";}'
killall Dock
