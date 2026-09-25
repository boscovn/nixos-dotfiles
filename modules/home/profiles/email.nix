# Terminal mail stack (aerc, mbsync, msmtp, notmuch, hydroxide). Opt-in: it
# needs the gopass setup and a ~/Maildir. Thunderbird is added by the email
# module itself only when the desktop profile is also present.
{ ... }:
{
  imports = [ ../email ];
}
