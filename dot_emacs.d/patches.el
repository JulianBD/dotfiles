;;; patches.el --- Patches for upstream bugs -*- lexical-binding: t; no-byte-compile: t; -*-

;;; Commentary:

;; Workarounds for bugs in third-party packages, expressed with el-patch
;; (https://github.com/radian-software/el-patch) rather than as bare
;; redefinitions.
;;
;; The point of el-patch is that each patch stays honest: the body below is
;; a verbatim copy of upstream's definition except for the `el-patch-*'
;; directives, and `M-x el-patch-validate-all' re-reads the installed
;; source and tells you when a patch no longer matches -- i.e. when
;; upstream has changed the function out from under us. Run it after
;; package upgrades.
;;
;; To see exactly what a patch changes: `M-x el-patch-ediff-patch'.
;; To drop a patch once upstream fixes it: delete the form and restart.

;;; Code:

(require 'el-patch)

;;;; gptel -- OpenAI OAuth login fails in the browser for every account

;; gptel-openai-oauth.el wraps the redirect URI in `url-hexify-string'
;; before handing it to `url-build-query-string', which hexifies it again.
;; The redirect_uri therefore goes out double-encoded:
;;
;;   sent:      redirect_uri=http%253A%252F%252Flocalhost%253A1455%252F...
;;   decodes:   http%3A%2F%2Flocalhost%3A1455%2Fauth%2Fcallback  (literal %)
;;   should be: http://localhost:1455/auth/callback
;;
;; OpenAI rejects the unregistered redirect_uri before any account is
;; involved, which is why personal and work accounts fail identically.
;; Confirmed against auth.openai.com/oauth/authorize:
;;
;;   double-encoded -> /error?payload=...  {"kind":"AuthApiFailure"}
;;   plain          -> /log-in
;;
;; Both call sites need patching: OAuth requires the redirect_uri sent to
;; /oauth/token to match the one sent to /oauth/authorize, so fixing only
;; the authorize URL moves the failure to invalid_grant.
;;
;; This cannot be done by advising `url-hexify-string' to `identity' around
;; these functions -- `url-build-query-string' calls it internally, so
;; every other parameter would stop being encoded.
;;
;; Introduced by b61a799 (2026-06-30), present in gptel 20260715.1547, and
;; still unfixed on master as of 2026-07-21.

(el-patch-feature gptel-openai-oauth)

(with-eval-after-load 'gptel-openai-oauth

  (el-patch-defun gptel--openai-oauth-authorization-url (redirect-uri verifier state)
    "Return an OpenAI authorization URL for REDIRECT-URI.

VERIFIER is used to derive the PKCE code challenge.  STATE is
included in the authorization request and checked in the callback."
    (concat
     gptel--openai-oauth-url "/oauth/authorize?"
     (url-build-query-string
      `(("response_type" "code")
        ("client_id" ,gptel--openai-oauth-client-id)
        ("redirect_uri" ,(el-patch-swap (url-hexify-string redirect-uri)
                                        redirect-uri))
        ("scope" "openid profile email offline_access")
        ("code_challenge" ,(gptel-oauth--generate-code-challenge verifier))
        ("code_challenge_method" "S256")
        ("id_token_add_organizations" "true")
        ("prompt" "login")
        ("codex_cli_simplified_flow" "true")
        ("state" ,state)
        ("originator" "gptel")))))

  (el-patch-defun gptel--openai-oauth-login-with-authorization-code (backend)
    "Authenticate BACKEND using OpenAI Authorization Code Flow with PKCE."
    (let* ((redirect-uri (format "http://localhost:%d%s"
                                 gptel--openai-oauth-redirect-port
                                 gptel--openai-oauth-redirect-path))
           (verifier (gptel-oauth--generate-code-verifier))
           (state (secure-hash 'sha256 (format "%s%s" (float-time) (random))))
           (authorization-url
            (gptel--openai-oauth-authorization-url redirect-uri verifier state))
           (code (gptel--openai-oauth-read-code authorization-url state))
           (token-plist
            (gptel--url-retrieve (concat gptel--openai-oauth-url "/oauth/token")
              :method 'post
              :data (url-build-query-string
                     `(("grant_type" "authorization_code")
                       ("client_id" ,gptel--openai-oauth-client-id)
                       ("code" ,code)
                       ("code_verifier" ,verifier)
                       ("redirect_uri" ,(el-patch-swap (url-hexify-string redirect-uri)
                                                       redirect-uri))))
              :content-type "application/x-www-form-urlencoded")))
      (gptel--openai-oauth-persist backend token-plist))))

(provide 'patches)
;;; patches.el ends here
