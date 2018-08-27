#lang racket

(require ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/alloc
         racket/runtime-path)

(define-runtime-path libmyvalidate.so
  "libmyvalidate.so")

(define-runtime-path example.dtd-path
  "example.dtd")

(define-runtime-path my-so-errors.txt-path
  "my-so-errors.txt")

(define-ffi-definer define-xml2
  (ffi-lib "libxml2"))

(define-ffi-definer define-drvalidate
  (ffi-lib libmyvalidate.so))

(define _xmlDtdPtr
  (_cpointer 'xmlDtdPtr))

(define-xml2 xmlFreeDtd
  (_fun _xmlDtdPtr -> _void)
  #:wrap (deallocator))

(define-xml2 xmlParseDTD
  (_fun [_pointer = #f]
        [file : _file]
        -> [p : (_or-null _xmlDtdPtr)]
        -> (if p
               p
               (error 'xmlParseDTD
                      "could not parse DTD\n  given: ~e"
                      file)))
  #:wrap (allocator xmlFreeDtd))

(define-drvalidate my_validate
  (_fun _xmlDtdPtr
        _string/utf-8
        [pth : _file]
        -> [code : _uint]
        -> (match code
             [2 (error 'my_validate "internal error")]
             [1 (file->string pth)]
             [0 'valid])))

(define example.dtd-ptr
  (xmlParseDTD example.dtd-path))

(define bad-doc-str
  "<example><bad /></example>")

(define good-doc-str
  "<example><good /></example>")

(my_validate example.dtd-ptr
             good-doc-str
             my-so-errors.txt-path)

(my_validate example.dtd-ptr
             bad-doc-str
             my-so-errors.txt-path)

