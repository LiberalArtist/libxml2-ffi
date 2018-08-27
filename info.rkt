#lang info
(define collection "libxml2")
(define deps '("base"
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
