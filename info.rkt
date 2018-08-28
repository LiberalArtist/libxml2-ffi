#lang info
(define collection "libxml2")
(define deps '("base"
               ("xmllint-win32-x86_64" #:platform "win32\\x86_64"
                                       #:version "0.1")
               ("libxml2-x86_64-linux-natipkg" #:platform
                                               "x86_64-linux-natipkg")
               ))
(define build-deps '("scribble-lib"
                     "racket-doc"
                     "rackunit-lib"
                     "rackunit-spec"
                     ))
(define scribblings '(("scribblings/libxml2.scrbl" ())))
(define pkg-desc "Racket FFI bindings for libxml2")
(define version "0.0")
(define pkg-authors '(philip))
