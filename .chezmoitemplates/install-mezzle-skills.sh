# Keep skills linked to the editable checkout; opt into the security-review draft.
skills_source="${MEZZLE_SKILLS_SOURCE:-$HOME/dev/skills}"
if [ ! -d "$skills_source" ]; then
  mkdir -p "$(dirname "$skills_source")"
  git clone https://github.com/Mezzle/skills.git "$skills_source"
fi
if [ ! -f "$skills_source/scripts/install_skills.py" ]; then
  echo "Update $skills_source to a revision containing scripts/install_skills.py, then rerun this hook." >&2
  exit 1
fi
python3 "$skills_source/scripts/install_skills.py" --draft security-review
