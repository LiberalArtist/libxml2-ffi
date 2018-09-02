#lang racket/base

(require (except-in ffi/unsafe ->)
         ffi/unsafe/define
         racket/contract
         syntax/parse/define
         (for-syntax racket/base
                     syntax/parse))

(provide define-ffi-definer/fail)

(define-for-syntax (make-def-foreign/fail load-failed?-stx
                                          raw-define-foreign-stx
                                          make/load-failed-stx)
  (syntax-parser
    [(_ name:id (~describe "ffi type expression" type:expr)
        (~describe "binding option"
                   (~seq opt-kw:keyword opt-val:expr)) ...)
     #:with load-failed? load-failed?-stx
     #:with raw-define-foreign raw-define-foreign-stx
     #:with make/load-failed make/load-failed-stx
     #`(define name
         (cond
           [load-failed?
            (make/load-failed 'name)]
           [else
            (raw-define-foreign name type (~@ opt-kw opt-val) ...)
            name]))]))
     

(define-syntax-parser define-ffi-definer/fail
  [(_ define-foreign:id
      pth (~optional (~var version
                           (expr/c #'(or/c string?
                                           #f
                                           (listof (or/c string? #f)))
                                   #:name "version expression"))
                     #:defaults ([version.c #'#f]))
      (~alt (~optional (~seq #:on-load-failed
                             (~var on-load-failed
                                   (expr/c #'(-> any)
                                           #:name "#:on-load-failed function")))
                       #:name "#:on-load-failed clause"
                       #:defaults ([on-load-failed.c #'void]))
            (~optional (~seq #:library-available? library-available?:id)
                       #:name "#:library-available? clause")
            (~once (~seq #:make/load-failed
                         (~var make/load-failed
                               (expr/c #'(-> symbol? (-> any/c (... ...) any))
                                       #:name "#:make/load-failed function")))
                       #:name "#:make/load-failed clause"))
      ...)
   #:declare pth (expr/c #'(or/c path-string? #f)
                         #:name "path expression")
   #`(begin
       (define-values {lib-val load-failed?}
         (let* ([load-failed-val
                 (gensym 'load-failed)]
                [lib-val (ffi-lib pth.c version.c #:fail (λ ()
                                                           (on-load-failed.c)
                                                           load-failed-val))])
           (if (eq? load-failed-val lib-val)
               (values #f #t)
               (values lib-val #f))))
       (~? (define library-available?
             (not load-failed?)))
       (define-ffi-definer raw-define-foreign lib-val)
       (define the-make/load-failed
         make/load-failed.c)
       (define-syntax define-foreign
         (make-def-foreign/fail #'load-failed?
                                #'raw-define-foreign
                                #'the-make/load-failed)))])

#|
Example usage:
(define-ffi-definer/fail define-fail
  "n3tbrgbwfdv"
  #:on-load-failed (λ () (log-error "load failed"))
  #:make/load-failed (λ (who)
                       (λ _
                         (error who "couldn't load shared library"))))

(define-fail printf _fpointer)

;(printf)
|#
