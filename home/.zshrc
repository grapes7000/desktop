# ~/.zshrc — managed by Chezmoi.
# Oh My Zsh manages plugins; Starship draws the prompt.

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
[ -r "$ZSH/oh-my-zsh.sh" ] || export ZSH="/usr/share/oh-my-zsh"
ZSH_THEME=""
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

plugins=(
  git
  sudo
  fzf
  zoxide
  command-not-found
  colored-man-pages
  extract
  history-substring-search
)

[ -r "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"
for _p in /usr/share/zsh/plugins/zsh-autosuggestions /usr/share/zsh-autosuggestions /usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions; do
    [ -r "$_p/zsh-autosuggestions.zsh" ] && source "$_p/zsh-autosuggestions.zsh" && break
done
unset _p

HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt AUTO_CD
setopt CORRECT
setopt INTERACTIVE_COMMENTS

export EDITOR="${EDITOR:-nvim}"
export VISUAL="$EDITOR"
export PATH="$HOME/.local/bin:$PATH"


bindkey '^[[A' history-substring-search-up 2>/dev/null || true
bindkey '^[[B' history-substring-search-down 2>/dev/null || true

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=rounded --info=inline"
command -v fd >/dev/null 2>&1 && export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"

[ -f "$HOME/.config/zsh/aliases.zsh" ] && source "$HOME/.config/zsh/aliases.zsh"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
[ -r "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

for _p in /usr/share/zsh/plugins/zsh-syntax-highlighting /usr/share/zsh-syntax-highlighting /usr/share/oh-my-zsh/custom/plugins/zsh-syntax-highlighting; do
    [ -r "$_p/zsh-syntax-highlighting.zsh" ] && source "$_p/zsh-syntax-highlighting.zsh" && break
done
unset _p

# Pretty directory listings with Nerd Font icons
alias ls='eza --icons=always --group-directories-first'
alias ll='eza -la --icons=always --group-directories-first --git'
alias tree='eza --tree --icons=always'
