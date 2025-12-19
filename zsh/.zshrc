# Created by newuser for 5.9
eval "$(starship init zsh)"

# Zinit configuration
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"


# Safer default aliases
alias update='sudo nala update && sudo nala upgrade && sudo flatpak update'
alias rm='rm -i'        # Always ask for confirmation before deletion
alias cp='cp -i'        # Ask before overwriting
alias mv='mv -i'        # Ask before overwriting
alias ll='lsd -h -1 -l -a'      # Long listing format, human readable sizes
alias la='lsd -h -1 -l -a'     # Long listing, human readable, show hidden files
alias ff='fzf'


# History config
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history


# Good order
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting  # this must be last



# Bind keys for history search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down


eval "$(zoxide init zsh)"

# Word movement shortcuts
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word


# FZF key bindings and completions
[ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh
[ -f /usr/share/fzf/shell/completion.zsh ] && source /usr/share/fzf/shell/completion.zsh



setopt appendhistory             # Append rather than overwrite
setopt sharehistory              # Share across terminal sessions
setopt hist_ignore_all_dups      # Don’t record duplicated commands
setopt hist_ignore_space         # Skip commands prefixed with a space
setopt hist_reduce_blanks        # Remove superfluous blanks

# Zoxide (smart cd)
eval "$(zoxide init zsh)"


# Completion & colors
autoload -Uz compinit && compinit
autoload -U colors && colors

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'



