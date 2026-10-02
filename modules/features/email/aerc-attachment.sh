# aerc filter for any application/* part (aerc.nix): senders often label PDFs,
# spreadsheets or archives application/octet-stream (or bogus types like
# application/base64), so the real type comes from the attachment's
# extension or, failing that, its content (libmagic). Reads the part on stdin.
# @calendar@ is replaced with aerc's calendar filter by aerc.nix.

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
name=${AERC_FILENAME:-attachment}
f="$tmp/${name//\//_}"
cat >"$f"

ext=""
[[ $name == *.* ]] && ext=${name##*.}
ext=${ext,,}
mime=$(file --brief --mime-type "$f")

doc() { pandoc --from "$1" --to plain --columns=100 "$f"; }
# Blank or separator-only rows (common in spreadsheets) would make
# pandoc read an empty header row and reject the rest.
table() { sed '/^[,[:space:]]*$/d' "$2" | pandoc --from "$1" --to plain --columns=160; }

case "$ext:$mime" in
  pdf:* | *:application/pdf)
    # -layout keeps columns (receipts, tables); trim its padding and collapse
    # blank runs. No fmt: it splits deeply indented layout lines word by word.
    pdftotext -layout -nopgbrk -q "$f" - | sed 's/[[:space:]]*$//' | cat -s ;;
  docx:* | *:application/vnd.openxmlformats-officedocument.wordprocessingml.document)
    doc docx ;;
  odt:* | *:application/vnd.oasis.opendocument.text)
    doc odt ;;
  epub:* | *:application/epub+zip)
    doc epub ;;
  rtf:* | *:text/rtf | *:application/rtf)
    doc rtf ;;
  ipynb:*)
    doc ipynb ;;
  xlsx:* | *:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
    xlsx2csv --all "$f" "$tmp/sheets" >/dev/null
    for sheet in "$tmp"/sheets/*.csv; do
      printf '== %s ==\n\n' "$(basename "$sheet" .csv)"
      table csv "$sheet"
      echo
    done ;;
  csv:* | *:text/csv)
    table csv "$f" ;;
  tsv:* | *:text/tab-separated-values)
    table tsv "$f" ;;
  zip:* | 7z:* | rar:* | tar:* | tgz:* | gz:* | xz:* | zst:* \
    | *:application/zip | *:application/x-7z-compressed | *:application/x-rar \
    | *:application/x-tar | *:application/gzip | *:application/x-xz | *:application/zstd)
    bsdtar -tvf "$f" ;;
  ics:* | *:text/calendar)
    @calendar@ <"$f" ;;
  p7s:* | p7m:* | *:application/pkcs7-signature)
    openssl pkcs7 -inform DER -in "$f" -print_certs -noout ;;
  json:* | *:application/json)
    jq --color-output . "$f" ;;
  *:image/*)
    chafa --format symbols --size 100x40 "$f" ;;
  *:text/*)
    bat --color=always --paging=never --style=plain --file-name="$name" "$f" ;;
  *)
    printf '%s\n\n%s\n' "$(file --brief "$f")" "No viewer for this type: :open or :save it." ;;
esac
