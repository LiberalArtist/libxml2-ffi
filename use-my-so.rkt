#lang racket

(require ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/alloc
         "common.rkt"
         racket/runtime-path)

(define-runtime-path my-so-errors.txt-path
  "my-so-errors.txt")

(define-runtime-path libmyvalidate.so
  "libmyvalidate.so")

(define-ffi-definer define-myvalidate
  (ffi-lib libmyvalidate.so))

(define-myvalidate my_validate
  (_fun _xmlDtdPtr
        _xmlDocPtr
        [pth : _file]
        -> [code : _uint]
        -> (match code
             [2 (error 'my_validate "internal error")]
             [1 (file->string pth)]
             [0 'valid])))

(my_validate example.dtd-ptr
             good-doc
             my-so-errors.txt-path)

(my_validate example.dtd-ptr
             bad-doc
             my-so-errors.txt-path)

