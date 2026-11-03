# Sourced by gate.sh and validate.sh. Public repositories name roles, never
# agent sessions (Joshua, 2026-11-03). A Perl-syntax denylist of the session
# and relay names the fleet uses, plus handoff paths; git grep -P. Add a name
# here when a session is created. (The first gate used an ERE "\b", which
# git grep reads as a literal b, and so matched nothing real.)
SESSION_NAMES='\b(c4-fleet|c4-lead|c4-onboarding|c4-front-door|c4-core-lead|c4d-lead|c4-fleet-lead|income-to-|-to-income)\b|\.handoff/|-to-c4-[a-z-]+\b|\bc4-to-c4-'

# session_names_hits DIR: prints up to 8 matching lines in DIR's tracked text.
session_names_hits() {
    (cd "$1" && git grep -I -n -P "$SESSION_NAMES" -- ':!node_modules' ':!*.lock' ':!*.sum' 2>/dev/null | head -8) || true
}
