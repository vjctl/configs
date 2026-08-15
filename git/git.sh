mkdir -p $HOME/.config/git/hooks
cp git/git_hooks.sh $HOME/.config/git/hooks/pre-push
chmod +x $HOME/.config/git/hooks/pre-push
cp git/.gitignore $HOME/.config/git/ignore
cp git/.gitconfig $HOME/.config/git/config
git config --global core.hooksPath $HOME/.config/git/hooks
git config --global core.excludesfile ~/.config/git/ignore
