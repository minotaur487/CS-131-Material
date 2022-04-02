#lang racket

#| Question 1 |#
(define LAMBDA (string->symbol "\u03BB"))

; Uses ideas from TA help github:
;https://github.com/CS131-TA-team/UCLA_CS131_CodeHelp/tree/master/Scheme
(define (expr-compare x y) 
    (cond
        ; Handles when expressions are equal. Also takes care of boolean equivalence
        [(equal? x y) x]
        ; Handles boolean case
        [(and (boolean? x) (boolean? y)) (if x '% '(not %))]
        ; Handles when one is a list and the other isn't or 
                ; two lengths of different length
        [(or (not (list? x)) (not (list? y))
             (not (equal? (length x) (length y)))) `(if % ,x ,y)]
        ; Handles when both are lists
        [else (compare-lists x y)]
    )
)

(define (compare-lists x y)
    (cond
        [(not (or (equal? x '()) (equal? y '())))
            (cond
                ; Handle case when both are lists, recurse into list
                [(and (list? (car x)) (list? (car y)))
                    (cons (compare-lists (car x) (car y)) (compare-lists (cdr x) (cdr y)))]
                ; Handle case one one is a list
                [(or (list? (car x)) (list? (car y))) `(if % ,x ,y)]   
                ; Handle case when both are ifs
                [(and (equal? (car x) 'if) (equal? (car y) 'if)) (cons 'if (plain-compare-lists (cdr x) (cdr y)))]
                ; Handle case when one is if and one isn't.
                [(or (equal? (car x) 'if) (equal? (car y) 'if)) `(if % ,x ,y)]
                ; Handle case where either are quoted
                [(or (equal? (car x) 'quote) (equal? (car y) 'quote)) `(if % ,x ,y)]
                ; Handle case where both are lambda
                [(and (lambda? (car x)) (lambda? (car y))) (lambda-symbol-handler x y '() '())]
                ; Handle case where one is lambda and one isn't
                [(or (lambda? (car x)) (lambda? (car y))) `(if % ,x ,y)]
                ; Handles case for other identifiers
                [else (plain-compare-lists x y)]
            )]
        [else (plain-compare-lists x y)]
    )
)

(define (plain-compare-lists x y)
    (cond
        ; Consider base case; x is empty if and only if y is empty
        [(equal? x '()) '()]
        ; Current symbols are equivalent
        [(equal? (car x) (car y)) (cons (car x) (plain-compare-lists (cdr x) (cdr y)))]
        ; Else they aren't and we recurse
        [else (cons (expr-compare (car x) (car y)) (plain-compare-lists (cdr x) (cdr y)))]
    )    
)

(define (lambda-symbol-handler x y map-x map-y)
    (cond
        ; Handle when both are 'lambda
        [(and (equal? (car x) 'lambda) (equal? (car y) 'lambda))
            (lambda-expression-handler 'lambda (cdr x) (cdr y) map-x map-y)]
        ; Handle when at least one is a symbol
        [else (lambda-expression-handler LAMBDA (cdr x) (cdr y) map-x map-y)]
    )
)

#| Rest of lambda expression is passed in |#
(define (lambda-expression-handler sym lambda-x lambda-y map-x map-y)
    (cond
        ; Handle case when the arguments are lists
        [(and (list? (car lambda-x)) (list? (car lambda-y)))
            (cond
                ; Handle when there are different number of arguments
                [(not (equal? (length (car lambda-x)) (length (car lambda-y))))
                    (list sym (cons (expr-compare (car lambda-x) (car lambda-y))
                        (plain-compare-lists (cdr lambda-x) (cdr lambda-y))))]
                [else
                    (let ([new-map-x (xmap-builder (car lambda-x) (car lambda-y))]
                          [new-map-y (ymap-builder (car lambda-x) (car lambda-y))])
                        ; Process arguments
                        (list sym (lambda-arg-handler (car lambda-x) (car lambda-y)
                            (cons new-map-x map-x) (cons new-map-y map-y))
                        ; Process function body
                        (lambda-compare-lists (car (cdr lambda-x)) (car (cdr lambda-y))
                        (cons new-map-x map-x) (cons new-map-y map-y)))
                )]
            )]
        ; Handle case when one of the arguments are lists
        [(or (list? (car lambda-x)) (list? (car lambda-y))) (list sym `(if % ,lambda-x ,lambda-y))]
        ; Handle everything else
        [else (list sym (plain-compare-lists lambda-x lambda-y))]
    )
)

; Gets latest value for the key
(define (latest-mapping map-list key)
    (cond
        [(equal? map-list '()) "fail"]
        [(equal? (hash-ref (car map-list) key "fail") "fail") (latest-mapping (cdr map-list) key)]
        [else (hash-ref (car map-list) key "fail")]
    )
)

#| Given rest of lambda expression, ie '((body)) or '(body)|#
(define (lambda-body-handler lambda-x lambda-y map-x map-y)
    (let ([x-body (car lambda-x)]
          [y-body (car lambda-y)])
        (cond
            ; Handle when the body is a list
            [(and (list? x-body) (list? y-body))
                (cond
                    [(equal? x-body '()) '()]
                    ; Handle if first symbol in body expression is a list
                    [(and (list? (car x-body)) (list? (car y-body)))
                        (cons (lambda-compare-lists (car x-body) (car y-body) map-x map-y)
                            (lambda-body-handler `(,(cdr x-body)) `(,(cdr y-body)) map-x map-y))]
                    ; Handle when you can retrieve from the maps
                    [(not (or (equal? (latest-mapping map-x (car x-body)) "fail")
                                   (equal? (latest-mapping map-y (car y-body)) "fail")))
                        (cond
                            ; If the values are equal
                            [(equal? (latest-mapping map-x (car x-body)) (latest-mapping map-y (car y-body)))
                                (cons (latest-mapping map-x (car x-body))
                                    (lambda-body-handler `(,(cdr x-body)) `(,(cdr y-body)) map-x map-y))]
                            ; if the values are not equal
                            [else (cons (list 'if '% (latest-mapping map-x (car x-body))
                                (latest-mapping map-y (car y-body)))
                                (lambda-body-handler `(,(cdr x-body)) `(,(cdr y-body)) map-x map-y))]
                    )]
                    ; Expression to evaluate
                    ; Handle otherwise
                    [else 
                    (let ([x-b (if (equal? (latest-mapping map-x (car x-body)) "fail") (car x-body) (latest-mapping map-x (car x-body)))]
                          [y-b (if (equal? (latest-mapping map-y (car y-body)) "fail") (car y-body) (latest-mapping map-y (car y-body)))])
                    (cond
                        [(not (equal? (car x-body) (car y-body)))
                        ; (print (list "start" y-body (hash-ref (car map-y) (car y-body) "fail") "end"))
                            (cons `(if % ,x-b ,y-b) (lambda-body-handler `(,(cdr x-body)) `(,(cdr y-body)) map-x map-y))]
                        [else (cons x-b (lambda-body-handler `(,(cdr x-body)) `(,(cdr y-body)) map-x map-y))]
                    ))]
            )]
            ; Handle when the body is not a list
            [else
                (let ([x-mapping (latest-mapping map-x x-body)]
                      [y-mapping (latest-mapping map-y y-body)])
                (cond
                    ; Handle hash map case
                    [(not (or (equal? x-mapping "fail")
                              (equal? y-mapping "fail")))
                        (cond
                            ; If the hash values are equal
                            [(equal? x-mapping y-mapping) x-mapping]
                            ; Otherwise indicate they aren't equal
                            [else `(if % ,x-mapping ,y-mapping)]
                        )
                    ]
                    ; Handle equals case
                    [(equal? x-body y-body) x-body]
                    ; Handle whatever else
                    [else `(if % ,x-body ,y-body)]
            ))]
        )
    )
)

; Assume we have same number of args
(define (lambda-arg-handler args-x args-y map-x map-y)
    (cond
        ; Handle when the args is a list
        [(and (list? args-x) (list? args-y))
            (cond
                ; Consider base case; x is empty if and only if y is empty
                [(equal? args-x '()) '()]
                ; Handle when you can retrieve from the maps and they are equal
                [(and
                        (not (or
                                (equal? (latest-mapping map-x (car args-x)) "fail")
                                (equal? (latest-mapping map-y (car args-y)) "fail")))
                        (equal? (latest-mapping map-x (car args-x)) (latest-mapping map-y (car args-y))))
                    (cons (latest-mapping map-x (car args-x)) (lambda-arg-handler (cdr args-x) (cdr args-y) map-x map-y))]
                ; Handle otherwise
                [else (cons (car args-x) (lambda-arg-handler (cdr args-x) (cdr args-y) map-x map-y))]
            )]
        ; Handle when the body is not a list
        [else
            (let ([x-mapping (latest-mapping map-x args-x)]
                  [y-mapping (latest-mapping map-y args-y)])
            (cond
                ; Handle hash map case
                [(and
                    (not (or
                            (equal? x-mapping "fail")
                            (equal? y-mapping "fail")))
                    (equal? x-mapping y-mapping))
                x-mapping]
                ; Handle equals case
                [(equal? args-x args-y) args-x]
                ; Handle whatever else
                [else `(if % ,args-x ,args-y)]
            ))]
    )
)

(define (lambda-expr-compare x y map-x map-y) 
    (cond
        ; Handles when expressions are equal. Also takes care of boolean equivalence
        [(equal? x y) x]
        ; Handles boolean case
        [(and (boolean? x) (boolean? y)) (if x '% '(not %))]
        ; Handles when one is a list and the other isn't or 
                ; two lengths of different length
        [(or (not (list? x)) (not (list? y))
             (not (equal? (length x) (length y)))) `(if % ,x ,y)]
        ; Handles when both are lists
        [else (lambda-compare-lists x y)]
    )
)

(define (lambda-compare-lists x y map-x map-y)
    (cond
        [(or (equal? x '()) (equal? y '())) (lambda-body-handler (list x) (list y) map-x map-y)]
        [(or (list? x) (list? y))
            (cond
            ; Handle case when both are lists, recurse into list
            [(and (list? (car x)) (list? (car y)))
                (cons (lambda-compare-lists (car x) (car y) map-x map-y) (lambda-compare-lists (cdr x) (cdr y) map-x map-y))]
            ; Handle case one one is a list
            [(or (list? (car x)) (list? (car y))) `(if % ,x ,y)]
            ; Handle case when both are ifs
            [(and (equal? (car x) 'if) (equal? (car y) 'if)) (cons 'if (lambda-body-handler (cdr x) (cdr y) map-x map-y))]
            ; Handle case when one is if and one isn't.
            [(or (equal? (car x) 'if) (equal? (car y) 'if)) `(if % ,x ,y)]
            ; Handle case where either are quoted
            [(or (equal? (car x) 'quote) (equal? (car y) 'quote)) `(if % ,x ,y)]

            ; Handle case where both are lambda
            [(and (lambda? (car x)) (lambda? (car y)))
                (lambda-symbol-handler x y map-x map-y)]
            ; Handle case where one is lambda and one isn't
            [(or (lambda? (car x)) (lambda? (car y))) `(if % ,x ,y)]

            ; Handles case for other identifiers
            [else (lambda-body-handler (list x) (list y) map-x map-y)]
        )]
        [else
            (cond
                ; Handle case when both are ifs
                [(and (equal? x 'if) (equal? y 'if)) (cons 'if (lambda-body-handler (cdr x) (cdr y) map-x map-y))]
                ; Handle case when one is if and one isn't.
                [(or (equal? x 'if) (equal? y 'if)) `(if % ,x ,y)]
                ; Handle case where either are quoted
                [(or (equal? x 'quote) (equal? y 'quote)) `(if % ,x ,y)]
                ; Handles case for other identifiers
                [else (lambda-body-handler (list x) (list y) map-x map-y)]
            ) 
        ])
)

#| Helper Functions |#
; Return #t if the current symbol is 'lambda' or the symbol lambda or #f
(define (lambda? x)
    (or (equal? x 'lambda) (equal? x LAMBDA))
)

(define (xmap-builder x-args y-args)
    (cond
        ; Base case. Scheme first evaluates arguments so it'll go all the way down the list first 
        [(equal? x-args '()) (hash)]
        ; Handle not equal case
        [(not (equal? (car x-args) (car y-args)))
            (hash-set
                ; recurse to get hashmap
                (xmap-builder (cdr x-args) (cdr y-args))
                ; key
                (car x-args)
                ; value
                (string->symbol (string-append (symbol->string (car x-args)) "!" (symbol->string (car y-args))))
            )]
        ; Rest of the cases should be when they're equal
        [else (xmap-builder (cdr x-args) (cdr y-args))]
    )
)

(define (ymap-builder x-args y-args)
    (cond
        ; Base case. Scheme first evaluates arguments so it'll go all the way down the list first
        ; Whether it's x-args or y-args shouldn't matter since there should be the same number of args
        [(equal? x-args '()) (hash)]
        ; Handle not equal case
        [(not (equal? (car x-args) (car y-args)))
            (hash-set
                ; recurse to get hashmap
                (ymap-builder (cdr x-args) (cdr y-args))
                ; key
                (car y-args)
                ; value
                (string->symbol (string-append (symbol->string (car x-args)) "!" (symbol->string (car y-args)))))]
        ; Rest of the cases should be when they're equal
        [else (ymap-builder (cdr x-args) (cdr y-args))]
    )
)

#| Question 2 |#
; Taken from the TA help github: https://github.com/CS131-TA-team/UCLA_CS131_CodeHelp/blob/master/Scheme/starting_hint.ss
; compare and see if the (expr-compare x y) result is the same with x when % = #t
;                                                 and the same with y when % = #f
; (define ns (make-base-namespace))
; (define (test-expr-compare x y) 
;   (and (equal? (eval x ns)
;                (eval `(let ((% #t)) ,(expr-compare x y)) ns))
;        (equal? (eval y ns)
;                (eval `(let ((% #f)) ,(expr-compare x y)) ns))))

(define (test-expr-compare x y) 
  (and (equal? (eval x)
               (eval `(let ((% #t)) ,(expr-compare x y))))
       (equal? (eval y)
               (eval `(let ((% #f)) ,(expr-compare x y))))))

#| Question 3 |#
(define test-expr-x
  '(cons (lambda (a b) ((lambda (if y z) (quote (if y z))) #f b a)) (if #t #t #f)))

(define test-expr-y
  '(cons (lambda (a d) ((lambda (if z) '(if y z)) #t a d)) (if #t #f #f)))

#| Test cases from spec |#
(equal? (expr-compare 12 12) '12)
(equal? (expr-compare 12 20) '(if % 12 20))
(equal? (expr-compare #t #t) #t)
(equal? (expr-compare #f #f) #f)
(equal? (expr-compare #t #f) '%)
(equal? (expr-compare #f #t) '(not %))
(equal? (expr-compare '(/ 1 0) '(/ 1 0.0)) '(/ 1 (if % 0 0.0)))
(equal? (expr-compare 'a '(cons a b)) '(if % a (cons a b)))
(equal? (expr-compare '(cons a b) '(cons a b)) '(cons a b))
(equal? (expr-compare '(cons a lambda) '(cons a λ)) '(cons a (if % lambda λ)))
(equal? (expr-compare '(cons (cons a b) (cons b c))
              '(cons (cons a c) (cons a c))) '(cons (cons a (if % b c)) (cons (if % b a) c)))
(equal? (expr-compare '(cons a b) '(list a b)) '((if % cons list) a b))
(equal? (expr-compare '(list) '(list a)) '(if % (list) (list a)))
(equal? (expr-compare ''(a b) ''(a c)) '(if % '(a b) '(a c)))
(equal? (expr-compare '(quote (a b)) '(quote (a c))) '(if % '(a b) '(a c)))
(equal? (expr-compare '(quoth (a b)) '(quoth (a c))) '(quoth (a (if % b c))))
(equal? (expr-compare '(if x y z) '(if x z z)) '(if x (if % y z) z))
(equal? (expr-compare '(if x y z) '(g x y z)) '(if % (if x y z) (g x y z)))
(equal? (expr-compare '((lambda (a) (f a)) 1) '((lambda (a) (g a)) 2)) '((lambda (a) ((if % f g) a)) (if % 1 2)))
(equal? (expr-compare '((lambda (a) (f a)) 1) '((λ (a) (g a)) 2)) '((λ (a) ((if % f g) a)) (if % 1 2)))
(equal? (expr-compare '((lambda (a) a) c) '((lambda (b) b) d)) '((lambda (a!b) a!b) (if % c d)))
(equal? (expr-compare ''((λ (a) a) c) ''((lambda (b) b) d)) '(if % '((λ (a) a) c) '((lambda (b) b) d)))
(equal? (expr-compare '(+ #f ((λ (a b) (f a b)) 1 2))
    '(+ #t ((lambda (a c) (f a c)) 1 2))) '(+ (not %) ((λ (a b!c) (f a b!c)) 1 2)))
(equal? (expr-compare '((λ (a b) (f a b)) 1 2)
    '((λ (a b) (f b a)) 1 2)) '((λ (a b) (f (if % a b) (if % b a))) 1 2))
(equal? (expr-compare '((λ (a b) (f a b)) 1 2)
    '((λ (a c) (f c a)) 1 2)) '((λ (a b!c) (f (if % a b!c) (if % b!c a))) 1 2))
(equal? (expr-compare '((lambda (lambda) (+ lambda if (f lambda))) 3)
    '((lambda (if) (+ if if (f λ))) 3)) '((lambda (lambda!if) (+ lambda!if (if % if lambda!if) (f (if % lambda!if λ)))) 3))
(equal? (expr-compare '((lambda (a) (eq? a ((λ (a b) ((λ (a b) (a b)) b a))
                                    a (lambda (a) a))))
                (lambda (b a) (b a)))
              '((λ (a) (eqv? a ((lambda (b a) ((lambda (a b) (a b)) b a))
                                a (λ (b) a))))
                (lambda (a b) (a b))))
  '((λ (a)
      ((if % eq? eqv?)
       a
       ((λ (a!b b!a) ((λ (a b) (a b)) (if % b!a a!b) (if % a!b b!a)))
        a (λ (a!b) (if % a!b a)))))
     (lambda (b!a a!b) (b!a a!b))))
