export ZSH="$HOME/.oh-my-zsh"
export HOMEBREW_NO_ENV_HINTS=1
export DISABLE_UNTRACKED_FILES_DIRTY="true"
export TERRAGRUNT_TFPATH="terraform"
export TERRAGRUNT_PROVIDER_CACHE=1
export TERRAGRUNT_NON_INTERACTIVE=true
export TERRAGRUNT_IGNORE_EXTERNAL_DEPENDENCIES=true
export TERRAGRUNT_FETCH_DEPENDENCY_OUTPUT_FROM_STATE=true
export TF_CLI_CONFIG_FILE="$HOME/.terraform.d/terraform.rc"
export DOCKER_DEFAULT_PLATFORM="linux/amd64"
plugins=(git
        z
        aliases
        #kube-ps1
        zsh-autosuggestions
        #zsh-autocomplete
        #fzf-zsh-plugin
        pyautoenv
        )
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
eval "$(pyenv init - zsh)"
source $ZSH/oh-my-zsh.sh
export PYENV_ROOT="$HOME/.pyenv"
# RPS1='$(kube_ps1)'
alias code='cursor'
alias dev='cd $HOME/Work/Git'
alias sts='sh $HOME/Work/scripts/aws_sts.sh'
alias refresh='source $HOME/.zshrc'
alias rc='code -e "$HOME/.zshrc"'
alias k='kubecolor'
alias kx='kubectx'
alias tg='terragrunt'
alias tgfmt='terragrunt hclfmt --terragrunt-check --terragrunt-diff'
alias tf='terraform'
alias spyder='nohup spyder --new-instance option & disown'
alias notebook='nohup jupyter-notebook & disown'
alias jupyter='docker rm pyspark && docker run -d -p 8888:8888 -e NB_UID=1000 -e GRANT_SUDO=yes --user root --name pyspark -v $HOME/Work/Git:/home/jovyan/work jupyter/pyspark-notebook && docker logs pyspark'export PATH="/usr/local/opt/libpq/bin:$PATH"
alias activate_poetry="source \"\$(poetry env list --full-path | grep Activated | cut -d' ' -f1 )/bin/activate\""

export PATH="/usr/local/opt/libpq/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/libpq/lib"
export CPPFLAGS="-I/usr/local/opt/libpq/include"
export PKG_CONFIG_PATH="/usr/local/opt/libpq/lib/pkgconfig"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

ns() {
    kubectl config set-context --current --namespace=$1
}
unalias gcl
gcl() {
    # prefix="temp"
    # local repo
    repo=$(basename -s .git "$1")
    # git clone "$1" "$prefix-$repo"
    # code "$prefix-$repo"
    git clone "$1"
    code "$repo"
}

# Herdr Config
if [[ -n "$HERDR_TAB_ID" ]]; then
  autoload -Uz add-zsh-hook

  _herdr_rename_tab() {
    local program="$1"
    local space_name=""

    if [[ -n "$HERDR_WORKSPACE_ID" ]]; then
      space_name=$(herdr workspace get "$HERDR_WORKSPACE_ID" 2>/dev/null | jq -r '.result.workspace.label // empty' 2>/dev/null)
    fi

    [[ -n "$space_name" ]] && program="$space_name - $program"
    herdr tab rename "$HERDR_TAB_ID" "$program" >/dev/null 2>&1
  }

  _herdr_preexec() {
  _herdr_rename_tab ${${1%% *}:t}
  }

  _herdr_precmd() {
    _herdr_rename_tab "${SHELL:t}"
  }

  add-zsh-hook preexec _herdr_preexec
  add-zsh-hook precmd _herdr_precmd
fi

hdr() {
    local dir_name="${PWD:t}"
    local session="${HERDR_SESSION:-default}"
    local workspace_id workspace_list

    if ! HERDR_SESSION="$session" herdr status server --json 2>/dev/null | jq -e '.running' >/dev/null 2>&1; then
        HERDR_SESSION="$session" herdr server >/dev/null 2>&1 &!
        sleep 2
    fi

    workspace_list=$(HERDR_SESSION="$session" herdr workspace list) || return
    workspace_id=$(print -r -- "$workspace_list" | jq -r --arg label "$dir_name" \
        '.result.workspaces[]? | select(.label == $label) | .workspace_id' | head -n 1)

    if [[ -n "$workspace_id" ]]; then
        HERDR_SESSION="$session" herdr workspace focus "$workspace_id" >/dev/null || return
    else
        HERDR_SESSION="$session" herdr workspace create --cwd "$PWD" --label "$dir_name" --focus >/dev/null || return
    fi

    env -u HERDR_ENV HERDR_SESSION="$session" herdr "$@"
}
