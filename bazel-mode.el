;;; bazel-mode.el --- Emacs major mode for editing Bazel files -*- lexical-binding:t; -*-

;; Copyright (C) 2018 Robert E. Brown.

;; Bazel Mode is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; Bazel Mode is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Bazel Mode.  If not, see <http://www.gnu.org/licenses/>.

;; Author: Robert E. Brown <robert.brown@gmail.com>

(require 'cl-lib)
(require 'python)

(defgroup bazel nil
  "Major mode for editing Bazel code."
  :group 'languages
  :link '(url-link "https://github.com/brown/bazel-mode"))

(defcustom bazel-mode-hook nil
  "Hook called by `bazel-mode'."
  :type 'hook
  :group 'bazel)

(defcustom buildifier-command "buildifier"
  "The command used to format Bazel Starlark files."
  :type 'string
  :group 'bazel)

(defcustom buildifier-diff-command "diff"
  "The command used by buildifier to create a diff of formatting changes to a
Bazel Starlark file.  To be used by Bazel Mode, the buildifier-diff-command
must produce output compatible with that of diff."
  :type 'string
  :group 'bazel)

(defvar bazel-font-lock-keywords
  `(;; keywords
    ,(rx symbol-start
         (or "and" "break" "continue" "ctx" "def" "elif" "else" "fail" "for" "if" "in" "load"
             "not" "or" "pass" "return" "self")
         symbol-end)
    ;; function definitions
    (,(rx symbol-start "def" (1+ space) (group (1+ (or word ?_))))
     (1 font-lock-function-name-face))
    ;; constants from Runtime.java
    (,(rx symbol-start (or "False" "None" "True") symbol-end)
     . font-lock-constant-face)
    ;; built-in functions
    (,(rx symbol-start
          (or
           ;; Starlark.

           ;; from MethodLibrary.java
           "all" "any" "bool" "capitalize" "count" "dict" "dir" "elems" "endswith" "enumerate"
           "fail" "find" "format" "getattr" "hasattr" "hash" "index" "int" "isalnum" "isalpha"
           "isdigit" "islower" "isspace" "istitle" "isupper" "join" "len" "list" "lower" "lstrip"
           "max" "min" "partition" "print" "range" "replace" "repr" "reversed" "rfind" "rindex"
           "rpartition" "rsplit" "rstrip" "sorted" "split" "splitlines" "startswith" "str" "strip"
           "title" "tuple" "upper" "zip"
           ;; from BazelLibrary.java
           "depset" "select" "to_list" "type" "union"
           ;; from SkylarkRepositoryModule.java
           "repository_rule"
           ;; from SkylarkAttr.java
           "configuration_field"
           ;; from SkylarkRuleClassFunctions.java
           "Actions" "aspect" "DefaultInfo" "Label" "OutputGroupInfo" "provider" "rule" "struct"
           "to_json" "to_proto"
           ;; from PackageFactory.java
           "distribs" "environment_group" "exports_files" "glob" "licenses" "native" "package"
           "package_group" "package_name" "repository_name"
           ;; from WorkspaceFactory.java
           "register_execution_platforms" "register_toolchains" "workspace"
           ;; from SkylarkNativeModule.java but not also in PackageFactory.java
           "existing_rule" "existing_rules"
           ;; from searching Bazel's Java code for "BLAZE_RULES".
           "aar_import" "action_listener" "alias" "android_binary" "android_device"
           "android_instrumentation_test" "android_library" "android_local_test"
           "android_ndk_repository" "android_sdk_repository" "apple_binary" "apple_static_library"
           "apple_stub_binary" "bind" "cc_binary" "cc_import" "cc_library" "cc_proto_library"
           "cc_test" "config_setting" "constraint_setting" "constraint_value" "extra_action"
           "filegroup" "genquery" "genrule" "git_repository" "http_archive" "http_file" "http_jar"
           "j2objc_library" "java_binary" "java_import" "java_library" "java_lite_proto_library"
           "java_package_configuration" "java_plugin" "java_proto_library" "java_runtime"
           "java_runtime_suite" "java_test" "java_toolchain" "local_repository" "maven_jar"
           "maven_server" "new_git_repository" "new_http_archive" "new_local_repository"
           "objc_bundle" "objc_bundle_library" "objc_framework" "objc_import" "objc_library"
           "objc_proto_library" "platform" "proto_lang_toolchain" "proto_library"
           "sh_binary" "sh_library" "sh_test" "test_suite"
           "toolchain" "xcode_config" "xcode_version"

           ;; Language rules.

           ;; Apple rules.  https://github.com/bazelbuild/rules_apple/tree/master/doc
           "apple_bundle_import" "apple_bundle_version" "apple_dynamic_framework_import"
           "apple_resource_bundle" "apple_resource_group" "apple_static_framework_import"
           "ios_application" "ios_build_test" "ios_extension" "ios_framework"
           "ios_imessage_application" "ios_imessage_extension" "ios_static_framework"
           "ios_sticker_pack_extension" "ios_ui_test" "ios_ui_test_suite" "ios_unit_test"
           "ios_unit_test_suite"
           "macos_application" "macos_build_test" "macos_bundle" "macos_command_line_application"
           "macos_extension" "macos_unit_test"
           "tvos_application" "tvos_build_test" "tvos_extension" "tvos_ui_test" "tvos_unit_test"
           "watchos_application" "watchos_build_test" "watchos_extension"
           ;; Closure rules.  https://github.com/bazelbuild/rules_closure
           "closure_css_binary" "closure_css_library" "closure_grpc_web_library"
           "closure_java_template_library" "closure_js_binary" "closure_js_deps"
           "closure_js_library" "closure_js_proto_library" "closure_js_template_library"
           "closure_js_test" "closure_proto_library" "closure_py_template_library" "phantomjs_test"
           ;; D rules.  https://github.com/bazelbuild/rules_d
           "d_binary" "d_docs" "d_library" "d_source_library" "d_test"
           ;; Docker rules.  https://github.com/bazelbuild/rules_docker
           "container_bundle" "container_image" "container_import" "container_load"
           "container_pull" "container_push"
           "cc_image" "d_image" "go_image" "groovy_image" "java_image" "nodejs_image" "py3_image"
           "py_image" "rust_image" "scala_image" "war_image"
           "add_apt_key" "download_pkgs" "install_pkgs"
           "container_run_and_commit" "container_run_and_commit_layer" "container_run_and_extract"
           ;; Gazelle Go rules.  https://github.com/bazelbuild/bazel-gazelle
           "gazelle" "gazelle_dependencies"
           ;; Go rules.  https://github.com/bazelbuild/rules_go
           "go_binary" "go_context" "go_download_sdk" "go_embed_data" "go_host_sdk" "go_library"
           "go_local_sdk" "go_path" "go_proto_compiler" "go_proto_library" "go_register_toolchains"
           "go_repository" "go_rules_dependencies" "go_source" "go_test" "go_toolchain"
           "go_wrap_sdk"
           ;; Groovy rules.  https://github.com/bazelbuild/rules_groovy
           "groovy_and_java_library" "groovy_binary" "groovy_junit_test" "groovy_library"
           "spock_test"
           ;; Jsonnet rules.  https://github.com/bazelbuild/rules_jsonnet
           "jsonnet_library" "jsonnet_to_json" "jsonnet_to_json_test"
           ;; Kotlin rules.  https://github.com/bazelbuild/rules_kotlin
           "define_kt_toolchain" "kotlin_repositories" "kt_android_library" "kt_compiler_plugin"
           "kt_javac_options" "kt_js_import" "kt_js_library" "kt_jvm_binary" "kt_jvm_import"
           "kt_jvm_library" "kt_jvm_test" "kt_kotlinc_options" "kt_register_toolchains"
           ;; Kubernetes rules.  https://github.com/bazelbuild/rules_k8s
           "k8s_defaults" "k8s_object" "k8s_objects"
           ;; Lisp rules.  https://github.com/qitab/bazelisp
           "lisp_binary" "lisp_library" "lisp_test"
           ;; Maven rules.
           "artifact" "maven_install" "pinned_maven_install"
           ;; Node.js rules.
           "check_bazel_version" "history" "http_server" "node_repositories" "nodejs_binary"
           "nodejs_test" "npm_install" "npm_package" "rollup_bundle" "yarn_install"
           ;; Package rules.  https://github.com/bazelbuild/rules_pkg
           "deb_packages" "pkg_deb" "pkg_rpm" "pkg_tar" "pkg_zip" "update_deb_packages"
           ;; Perl rules.  https://github.com/bazelbuild/rules_perl
           "perl_binary" "perl_library" "perl_test"
           ;; Rust rules.  https://bazelbuild.github.io/rules_rust
           "cargo_build_script" "rust_analyzer" "rust_analyzer_aspect" "rust_benchmark"
           "rust_binary" "rust_bindgen" "rust_bindgen_library" "rust_bindgen_repositories"
           "rust_bindgen_toolchain" "rust_clippy" "rust_clippy_aspect" "rust_doc" "rust_doc_test"
           "rust_grpc_library" "rust_library" "rust_proc_macro" "rust_proto_library"
           "rust_proto_repositories" "rust_proto_toolchain" "rust_repositories"
           "rust_repository_set" "rust_shared_library" "rust_static_library" "rust_test"
           "rust_test_suite" "rust_toolchain" "rust_toolchain_repository"
           "rust_toolchain_repository_proxy" "rust_wasm_bindgen" "rust_wasm_bindgen_repositories"
           "rust_wasm_bindgen_toolchain"
           ;; Python rules.  https://github.com/bazelbuild/rules_python
           "pip_import" "pip_install" "pip_parse"
           "py_binary" "py_library" "py_runtime" "py_runtime_pair" "py_test"
           ;; Scala rules.  https://github.com/bazelbuild/rules_scala
           "scala_binary" "scala_doc" "scala_import" "scala_library" "scala_library_suite"
           "scala_macro_library" "scala_proto_library" "scala_repl" "scala_test" "scala_test_suite"
           "scala_toolchain" "thrift_library"
           ;; Swift rules.  https://github.com/bazelbuild/rules_swift
           "SwiftInfo" "SwiftToolchainInfo" "swift_binary" "swift_c_module" "swift_common"
           "swift_import" "swift_library" "swift_module_alias" "swift_proto_library"
           "swift_rules_dependencies" "swift_test"
           )
          symbol-end)
     . font-lock-builtin-face)
    ;; TODO:  Handle assignments better.  The code below fontifies a[b] = 1 and a = b = 2.
    ,(nth 7 python-font-lock-keywords)
    ,(nth 8 python-font-lock-keywords)
    ))

(defvar bazel-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-f") 'bazel-format)
    map))

(define-derived-mode bazel-mode python-mode "Bazel"
  "Major mode for editing Bazel files.

\\{bazel-mode-map}"
  :group 'bazel

  (setq python-indent-guess-indent-offset nil
        python-indent-offset 4)

  ;; Replace Python keyword fontification with Starlark keyword fontification.
  (setq font-lock-defaults
        '(bazel-font-lock-keywords
          nil nil nil nil
          (font-lock-syntactic-face-function . python-font-lock-syntactic-face-function))))

(defun starlark-file-type (file-name)
  (let* ((dot (cl-position ?. file-name :from-end t))
         (base (if dot (subseq file-name 0 dot) file-name))
         (extension (if dot (subseq file-name (1+ dot)) "")))
    (cond ((or (string= base "BUILD") (string= extension "BUILD")) "build")
          ((or (string= base "WORKSPACE") (string= extension "WORKSPACE")) "workspace")
          (t "bzl"))))

(defun bazel-parse-diff-action ()
  (unless (looking-at (rx line-start
                          (group (+ digit)) (? ?, (group (+ digit)))
                          (group (| ?a ?d ?c))
                          (group (+ digit)) (? ?, (group (+ digit)))
                          line-end))
    (error "bad buildifier diff output"))
  (let* ((orig-start (string-to-number (match-string 1)))
         (orig-count (if (null (match-string 2))
                         1
                       (1+ (- (string-to-number (match-string 2)) orig-start))))
         (command (match-string 3))
         (formatted-count (if (null (match-string 5))
                              1
                            (1+ (- (string-to-number (match-string 5))
                                   (string-to-number (match-string 4)))))))
    (list command orig-start orig-count formatted-count)))

(defun bazel-patch-buffer (buffer diff-buffer)
  "Applies the diff editing actions contained in DIFF-BUFFER to BUFFER."
  (with-current-buffer buffer
    (save-restriction
      (widen)
      (goto-char (point-min))
      (let ((orig-offset 0)
            (current-line 1))
        (cl-flet ((goto-orig-line (orig-line)
                    (let ((desired-line (+ orig-line orig-offset)))
                      (forward-line (- desired-line current-line))
                      (setq current-line desired-line)))
                  (insert-lines (lines)
                    (dolist (line lines) (insert line))
                    (cl-incf current-line (length lines))
                    (cl-incf orig-offset (length lines)))
                  (delete-lines (count)
                    (let ((start (point)))
                      (forward-line count)
                      (delete-region start (point)))
                    (cl-decf orig-offset count)))
          (save-excursion
            (with-current-buffer diff-buffer
              (goto-char (point-min))
              (while (not (eobp))
                (cl-multiple-value-bind (command orig-start orig-count formatted-count)
                    (bazel-parse-diff-action)
                  (forward-line)
                  (cl-flet ((fetch-lines ()
                            (cl-loop repeat formatted-count
                                     collect (let ((start (point)))
                                               (forward-line 1)
                                               ;; Return only the text after "< " or "> ".
                                               (substring (buffer-substring start (point)) 2)))))
                    (cond ((equal command "a")
                           (let ((lines (fetch-lines)))
                             (with-current-buffer buffer
                               (goto-orig-line (1+ orig-start))
                               (insert-lines lines))))
                          ((equal command "d")
                           (forward-line orig-count)
                           (with-current-buffer buffer
                             (goto-orig-line orig-start)
                             (delete-lines orig-count)))
                          ((equal command "c")
                           (forward-line (+ orig-count 1))
                           (let ((lines (fetch-lines)))
                             (with-current-buffer buffer
                               (goto-orig-line orig-start)
                               (delete-lines orig-count)
                               (insert-lines lines)))))))))))))))

(defun bazel-format ()
  "Format the current buffer using buildifier."
  (interactive)
  (let ((input-file nil)
        (output-buffer nil)
        (errors-file nil)
        (file-name (file-name-nondirectory (buffer-file-name))))
    (unwind-protect
        (progn
          (setf input-file (make-temp-file "bazel-format-input-")
                output-buffer (get-buffer-create "*bazel-format-output*")
                errors-file (make-temp-file "bazel-format-errors-"))
          (write-region nil nil input-file nil 'silent-write)
          (with-current-buffer output-buffer (erase-buffer))
          (let ((status
                 (call-process buildifier-command nil `(,output-buffer ,errors-file) nil
                               (concat "--diff_command=" buildifier-diff-command)
                               "--mode=diff"
                               (concat "--type=" (starlark-file-type file-name))
                               input-file)))
            (cl-case status
              ;; No reformatting needed or reformatting was successful.
              ((0 4)
               (save-excursion (bazel-patch-buffer (current-buffer) output-buffer))
               ;; Delete any previously created errors buffer.
               (let ((errors-buffer (get-buffer "*BazelFormatErrors*")))
                 (when errors-buffer (kill-buffer errors-buffer))))
              (t
               (cl-case status
                 (1 (message "Starlark language syntax errors"))
                 (2 (message "buildifier invoked incorrectly or cannot run diff"))
                 (3 (message "buildifier encountered an unexpected run-time error"))
                 (t (message "unknown buildifier error")))
               (sit-for 1)
               (let ((errors-buffer (get-buffer-create "*BazelFormatErrors*")))
                 (with-current-buffer errors-buffer
                   ;; A previously created errors buffer is read only.
                   (setq buffer-read-only nil)
                   (erase-buffer)
                   (let ((coding-system-for-read "utf-8"))
                     (insert-file-contents-literally errors-file))
                   (when (= status 1)
                     ;; Replace the name of the temporary input file with that
                     ;; of the name of the file we are saving in all syntax
                     ;; error messages.
                     (let ((regexp (rx-to-string `(sequence line-start (group ,input-file) ":"))))
                       (while (search-forward-regexp regexp nil t)
                         (replace-match file-name t t nil 1)))
                     ;; Use compilation mode so next-error can be used to find
                     ;; the errors.
                     (goto-char (point-min))
                     (compilation-mode)))
                 (display-buffer errors-buffer))))))
      (when input-file (delete-file input-file))
      (when output-buffer (kill-buffer output-buffer))
      (when errors-file (delete-file errors-file)))))

(provide 'bazel-mode)

;;; bazel-mode.el ends here
