#lang racket/base

(require ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/alloc
         xml
         racket/file
         (rename-in racket/contract
                    [-> ->/c]))

;; TODO: what about ill-formed documents?

(provide dtd?
         (contract-out
          [file->dtd
           (->/c path-string? dtd?)]
          [dtd-validate-xexpr
           (dtd-validate-proc/c xexpr/c)]
          [dtd-validate-xml-string
           (dtd-validate-proc/c string?)]
          [dtd-validate-xml-file
           (dtd-validate-proc/c
            (and/c path-string? file-exists?))]
          ))

(define (dtd-validate-proc/c doc/c)
  (->* {dtd?
        doc/c}
       {(or/c #f path-string?)}
       (or/c 'valid
             (and/c string? immutable?))))

(define-ffi-definer define-xml2
  (ffi-lib "libxml2"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; xmlDTD

(struct dtd (ptr))

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

(define (file->dtd pth)
  (dtd (xmlParseDTD (path->complete-path pth))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; xmlDoc

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; xmlValidCtxt

(define-ffi-definer define-libc
  (ffi-lib #f))

(define _fprintf-ptr
  _fpointer)

(define-libc fprintf-ptr
  _fprintf-ptr
  #:c-id fprintf)

(define _FILE-ptr
  (_cpointer 'FILE))

(define-libc fclose
  (_fun _FILE-ptr
        -> [code : _int]
        -> (unless (= 0 code)
             ;; see errno
             (error 'fclose "failed")))
  #:wrap (deallocator))

(define-libc fopen/write
  (_fun [file : _file]
        [_bytes/nul-terminated = #"w"]
        -> [p : (_or-null _FILE-ptr)]
        -> (if p
               p
               (error 'fopen/write
                      "fopen failed\n  given: ~e"
                      file)))
  #:wrap (allocator fclose)
  #:c-id fopen)

(define-cstruct _xmlValidCtxt
  ([userData _FILE-ptr] ;; user specific data block 
   [error _fprintf-ptr] ;; the callback in case of errors
   [warning _fprintf-ptr] ;; the callback in case of warning
   [node _pointer] ;; Current parsed Node
   [nodeNr _int] ;; Depth of the parsing stack
   [nodeMax _int] ;; Max depth of the parsing stack
   [nodeTab _pointer] ;; array of nodes
   [finishDtd _uint] ;; finished validating the Dtd ?
   [doc _xmlDocPtr] ;; the document
   [valid _int] ;; temporary validity check result state s
   [vstate _pointer] ;; current state
   [vstateNr _int] ;; Depth of the validation stack
   [vstateMax _int] ;; Max depth of the validation stack
   [vstateTab _pointer] ;; array of validation states
   [am _pointer] ;; the automata
   [state _pointer] ;; used to build the automata
   ))

(define _xmlValidCtxtPtr
  _xmlValidCtxt-pointer)

(define-xml2 xmlFreeValidCtxt
  (_fun _xmlValidCtxtPtr -> _void)
  #:wrap (deallocator))

(define-xml2 xmlNewValidCtxt
  (_fun -> [p : (_or-null _xmlValidCtxtPtr)]
        -> (if p
               p
               (error 'xmlNewValidCtxt
                      "couldn't allocate validation context")))
  #:wrap (allocator xmlFreeValidCtxt))

(define-xml2 xmlValidateDtd
  (_fun _xmlValidCtxtPtr _xmlDocPtr _xmlDtdPtr
        -> [code : _int]
        -> (= 1 code)))

(define (do-validate dtd doc errors-path)
  (define valid-ctxt-ptr
    (xmlNewValidCtxt))
  (define errors-file-ptr
    (fopen/write errors-path))
  (set-xmlValidCtxt-userData! valid-ctxt-ptr errors-file-ptr)
  (set-xmlValidCtxt-error! valid-ctxt-ptr fprintf-ptr)
  (set-xmlValidCtxt-warning! valid-ctxt-ptr fprintf-ptr)
  (define valid?
    (xmlValidateDtd valid-ctxt-ptr doc dtd))
  (fclose errors-file-ptr)
  (xmlFreeValidCtxt valid-ctxt-ptr)
  (if valid?
      'valid
      (string->immutable-string
       (file->string errors-path #:mode 'text))))

(define (dtd-validate-xml* -dtd doc arg-err-pth)
  (define errors-file-pth
    (or arg-err-pth
        (make-temporary-file)))
  (define rslt
    (do-validate (dtd-ptr -dtd)
                 doc
                 errors-file-pth))
  (xmlFreeDoc doc)
  (unless arg-err-pth
    (delete-file errors-file-pth))
  rslt)

(define (dtd-validate-xml-string -dtd str [arg-err-pth #f])
  (dtd-validate-xml* -dtd (xmlParseDoc str) arg-err-pth))

(define (dtd-validate-xml-file -dtd pth [arg-err-pth #f])
  (dtd-validate-xml* -dtd
                     (xmlParseFile (path->complete-path pth))
                     arg-err-pth))

(define (dtd-validate-xexpr -dtd xs [arg-err-pth #f])
  (dtd-validate-xml-string -dtd (xexpr->string xs) arg-err-pth))


