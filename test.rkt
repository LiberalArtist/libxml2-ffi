#lang racket/base

(module+ test
  (require "main.rkt"
           rackunit
           rackunit/spec
           racket/match
           racket/file
           racket/runtime-path)
  (provide example.dtd-path
           example.dtd
           good.xml-path
           bad.xml-path
           ill-formed.xml-path
           good-str
           bad-str
           ill-formed-str
           good-xexpr
           bad-xexpr)

  (define-runtime-path example.dtd-path
    "test/example.dtd")
  (define-runtime-path good.xml-path
    "test/good.xml")
  (define-runtime-path bad.xml-path
    "test/bad.xml")
  (define-runtime-path ill-formed.xml-path
    "test/ill-formed.xml")
  
  (define good-str
    "<example><good /></example>")
  (define bad-str
    "<example><bad /></example>")
  (define ill-formed-str
    "<a")

  (define good-xexpr
    '(example (good)))
  (define bad-xexpr
    '(example (bad)))

  (describe
   "file->dtd"
   (it "works with absolute path"
       (check-not-exn
        (λ ()
          (file->dtd example.dtd-path))))
   (it "works with relative path"
       (check-not-exn
        (λ ()
          (match-define-values {base name _}
            (split-path example.dtd-path))
          (parameterize ([current-directory base])
            (file->dtd name)))
        "file->dtd: relative path")))

  (define example.dtd
    (file->dtd example.dtd-path))

  (define error-buffer-file
    (make-temporary-file))

  (define-simple-check (check-valid v)
    (eq? 'valid v))
  (define-simple-check (check-invalid v)
    (string? v))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (describe
   "dtd-validate-xml-string"
   (context
    "with automatic error buffer file"
    (it "recognizes a valid string"
        (check-valid
         (dtd-validate-xml-string example.dtd
                                  good-str)))
    (it "rejects an ill-formed string"
        (check-invalid
         (dtd-validate-xml-string example.dtd
                                  ill-formed-str)))
    (it "rejects an invalid string"
        (check-invalid
         (dtd-validate-xml-string example.dtd
                                  bad-str
                                  #f))))
   (context
    "with re-used error buffer file"
    (it "recognizes a valid string"
        (check-valid
         (dtd-validate-xml-string example.dtd
                                  good-str
                                  error-buffer-file)))
    (it "rejects an ill-formed string"
        (check-invalid
         (dtd-validate-xml-string example.dtd
                                  ill-formed-str
                                  error-buffer-file)))
    (it "rejects an invalid string"
        (check-invalid
         (dtd-validate-xml-string example.dtd
                                  bad-str
                                  error-buffer-file)))))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (describe
   "dtd-validate-xexpr"
   (context
    "with re-used error buffer file"
    (it "recognizes a valid xexpr"
        (check-valid
         (dtd-validate-xexpr example.dtd
                             good-xexpr
                             error-buffer-file)))
    (it "rejects an invalid xexpr"
        (check-invalid
         (dtd-validate-xexpr example.dtd
                             bad-xexpr
                             error-buffer-file)))))


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (describe
   "dtd-validate-xml-file"
   (context
    "with re-used error buffer file"
    (context
     "with an absolute path"
     (it "recognizes a valid file"
         (check-valid
          (dtd-validate-xml-file example.dtd
                                 good.xml-path
                                 error-buffer-file)))
     (it "rejects an ill-formed file"
         (check-invalid
          (dtd-validate-xml-file example.dtd
                                 ill-formed.xml-path
                                 error-buffer-file)))
     (it "rejects an invalid file"
         (check-invalid
          (dtd-validate-xml-file example.dtd
                                 bad.xml-path
                                 error-buffer-file))))
    (context
     "with a relative path"
     (match-define-values {base good-name _}
       (split-path good.xml-path))
     (parameterize ([current-directory base])
       (it "recognizes a valid file"
           (check-valid
            (dtd-validate-xml-file example.dtd
                                   good-name
                                   error-buffer-file)))
       (match-define-values {_ ill-formed-name _}
         (split-path ill-formed.xml-path))
       (it "rejects an ill-formed file"
           (check-invalid
            (dtd-validate-xml-file example.dtd
                                   ill-formed-name
                                   error-buffer-file)))
       (match-define-values {_ bad-name _}
         (split-path bad.xml-path))
       (it "rejects an invalid file"
           (check-invalid
            (dtd-validate-xml-file example.dtd
                                   bad-name
                                   error-buffer-file)))))))

  (delete-file error-buffer-file)
  #|END module+ test|#)





