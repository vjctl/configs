mkdir -p $HOME/.config/.githooks
cp git/git_hooks.sh $HOME/.config/.githooks/pre-push
chmod +x $HOME/.config/.githooks/pre-push
git config core.hooksPath $HOME/.config/.githooks
