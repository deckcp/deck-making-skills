#!/usr/bin/env bash
# gh-person.sh — resolve a person from GitHub: by username, by commit, or by
# email (best-effort). Uses the authenticated `gh` CLI (its built-in --jq needs
# no external jq). Zero model tokens. Stock macOS bash 3.2 compatible.
#
# Usage:
#   gh-person.sh --user <login>
#   gh-person.sh --commit <sha> [--repo owner/name]
#   gh-person.sh --email <email>            # best-effort via commit search
#
# Prints a compact person card. Exit: 0 ok, 1 bad args, 2 gh missing/not auth,
# 3 not found.
set -eu

MODE=""
ARG=""
REPO=""

while [ $# -gt 0 ]; do
  case "$1" in
    --user)   MODE="user";   ARG="$2"; shift 2 ;;
    --commit) MODE="commit"; ARG="$2"; shift 2 ;;
    --email)  MODE="email";  ARG="$2"; shift 2 ;;
    --repo)   REPO="$2";     shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$MODE" ] || [ -z "$ARG" ]; then
  echo "usage: gh-person.sh (--user <login> | --commit <sha> [--repo o/n] | --email <email>)" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found — install it and run 'gh auth login'." >&2
  exit 2
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated — run 'gh auth login'." >&2
  exit 2
fi

# Print a profile card for a resolved login. node does the formatting so we
# don't fight bash field-splitting over empty/private fields. Returns 3 if the
# login doesn't resolve to a public user.
print_user_card() {
  login="$1"
  gh api "users/$login" 2>/dev/null | node -e '
    let s = "";
    process.stdin.on("data", d => s += d).on("end", () => {
      let j;
      try { j = JSON.parse(s); } catch { console.error("Could not parse GitHub response."); process.exit(3); }
      if (!j || !j.login || j.message === "Not Found") {
        console.error("No public GitHub user found for that login.");
        process.exit(3);
      }
      const row = (label, val) => {
        if (val == null || String(val).trim() === "") return;
        console.log(label + String(val).replace(/\n/g, " "));
      };
      row("Name:     ", j.name || "(name not public)");
      row("Login:    ", j.login);
      row("Email:    ", j.email || "(not public — use --commit for a commit-author email)");
      row("Company:  ", j.company);
      row("Location: ", j.location);
      row("Blog:     ", j.blog);
      row("Twitter:  ", j.twitter_username ? "@" + j.twitter_username : "");
      row("Bio:      ", j.bio);
      console.log("Repos:    " + (j.public_repos || 0) + " public · Followers: " + (j.followers || 0));
      row("Profile:  ", j.html_url);
    });
  '
}

case "$MODE" in
  user)
    print_user_card "$ARG"
    ;;

  commit)
    SHA="$ARG"
    # Local git author (works offline, always has the email the commit was made with).
    if git rev-parse --git-dir >/dev/null 2>&1 && git cat-file -e "$SHA" 2>/dev/null; then
      AUTHOR=$(git show -s --format='%an <%ae>' "$SHA")
      echo "Commit author (from git): $AUTHOR"
    fi
    # GitHub login for the commit needs repo context.
    if [ -z "$REPO" ]; then
      REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
    fi
    if [ -n "$REPO" ]; then
      LOGIN=$(gh api "repos/$REPO/commits/$SHA" --jq '.author.login // empty' 2>/dev/null || true)
      if [ -n "$LOGIN" ]; then
        echo "GitHub login:   $LOGIN  (via $REPO)"
        echo "---"
        print_user_card "$LOGIN"
      else
        echo "No linked GitHub account for that commit in $REPO (author may not have a GitHub-linked email)." >&2
      fi
    else
      echo "No --repo given and not inside a GitHub repo — showing git author only." >&2
    fi
    ;;

  email)
    # Best-effort: find a public commit authored by this email, read its login.
    echo "Searching public commits authored by $ARG …" >&2
    LOGIN=$(gh api -H "Accept: application/vnd.github.cloak-preview+json" \
      "search/commits?q=author-email:$ARG&per_page=1" \
      --jq '.items[0].author.login // empty' 2>/dev/null || true)
    if [ -n "$LOGIN" ]; then
      echo "Matched login: $LOGIN"
      echo "---"
      print_user_card "$LOGIN"
    else
      echo "No public commit found for $ARG — the address may be private or not used on public commits." >&2
      exit 3
    fi
    ;;
esac
