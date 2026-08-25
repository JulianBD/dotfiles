# pdf — text extraction, wrapping poppler's `pdftotext`.
#
#   use pdf.nu
#   pdf text paper.pdf                      # whole document, layout preserved
#   pdf text paper.pdf --first 2 --last 10  # a page range
#   pdf text paper.pdf --out paper.txt      # write a file, return its path
#   pdf text paper.pdf | lines | length
#
# `pdftotext` is the right tool for digital-born PDFs: deterministic, fast, no
# dependencies. It cannot read scanned pages — those have no text layer and
# need OCR (ocrmypdf, tesseract) — and this command says so rather than
# returning a confusing empty string.

# Extract text from a PDF.
#
# Layout mode is the default: it preserves column and table alignment, which
# is usually what makes extracted prose readable. Pass --raw for content
# stream order instead.
export def text [
    path: string           # PDF file
    --first (-f): int      # First page to convert (default: the first)
    --last (-l): int       # Last page to convert (default: the last)
    --raw (-r)             # Content stream order, rather than layout
    --out (-o): string     # Write here instead of returning the text
]: nothing -> string {
    if (which pdftotext | is-empty) {
        error make {msg: "pdftotext not found; install poppler (brew install poppler)"}
    }

    let file: string = ($path | path expand --no-symlink)
    if not ($file | path exists) {
        error make {msg: $"no such file: ($file)"}
    }

    # A wrong extension is common enough to be worth naming precisely, and the
    # magic number is cheaper than letting pdftotext fail obscurely.
    if (open --raw $file | first 4 | decode utf-8) != "%PDF" {
        error make {msg: $"not a PDF: ($file)"}
    }

    let destination: string = (
        if $out == null { "-" } else { $out | path expand --no-symlink }
    )
    let arguments: list<string> = (
        [(if $raw { "-raw" } else { "-layout" })]
        | append (if $first == null { [] } else { ["-f" ($first | into string)] })
        | append (if $last == null { [] } else { ["-l" ($last | into string)] })
        | append [$file $destination]
    )

    let result: record<exit_code: int, stdout: string, stderr: string> = (
        ^pdftotext ...$arguments | complete
    )
    if $result.exit_code != 0 {
        # Exit codes per the pdftotext man page; its own message is terse.
        let reason: string = match $result.exit_code {
            1 => "could not open the PDF"
            2 => "could not open the output file"
            3 => "not permitted (the PDF is probably encrypted)"
            _ => "failed"
        }
        error make {msg: $"pdftotext ($reason): ($result.stderr | str trim)"}
    }

    if $out != null {
        return $destination
    }
    if ($result.stdout | str trim | is-empty) {
        error make {msg: $"($file) yielded no text — it is probably scanned, and needs OCR (ocrmypdf, tesseract)"}
    }
    $result.stdout
}
