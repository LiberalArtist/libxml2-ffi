#lang racket

(require ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/alloc
         racket/runtime-path)

(provide define-xml2
         _xmlDtdPtr
         example.dtd-ptr
         bad-doc
         good-doc
         _xmlDocPtr
         )   

(define-runtime-path example.dtd-path
  "example.dtd")

(define-ffi-definer define-xml2
  (ffi-lib "libxml2"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DTD

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

(define example.dtd-ptr
  (xmlParseDTD example.dtd-path))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Doc

(define _xmlDocPtr
  (_cpointer 'xmlDocPtr))

(define-xml2 xmlFreeDoc
  (_fun _xmlDocPtr -> _void)
  #:wrap (deallocator))

(define-xml2 xmlParseDoc
  (_fun [s : _string/utf-8]
        -> [p : (_or-null _xmlDocPtr)]
        -> (if p
               p
               (error 'xmlParseDoc
                      "could not parse string\n  given...:\n   ~e"
                      s)))
  #:wrap (allocator xmlFreeDoc))

(define-xml2 xmlParseFile
  (_fun [file : _file]
        -> [p : (_or-null _xmlDocPtr)]
        -> (if p
               p
               (error 'xmlParseFile
                      "could not parse file\n  given: ~e"
                      file)))
  #:wrap (allocator xmlFreeDoc))

(define bad-doc
  (xmlParseDoc "<example><bad /></example>"))

(define good-doc
  (xmlParseDoc "<example><good /></example>"))

