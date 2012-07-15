(load "match")

(macro return (handler *body)
  (match *body
    ((:ok ok-form)
      `(,handler ',@ok-form))
    ((:abort code error original-message)
      (print "Uh-oh, aborting. Shit got real: #{code} #{error}.\n"))))

(macro background-message (*body)
  (print "Whoa got some background message all right. Dat #{*body}.\n"))

(macro process (command-parts)
  (match (eval command-parts)
    ((:incoming-function form sequence)
      (if (and (sequence respondsToSelector:"objCType") (== (sequence objCType) "q"))
          `(if (self pendingSequence:,sequence)
               (let (__handler (self sequenceSeen:,sequence))
                 (eval (,incoming-function __handler ,@form)))
               (else
                     (print (+ "Unexpected sequence: " ,sequence ".\n"))))
          (else
                `(,incoming-function ,form ,sequence))))
    ((. rest)
      (let ((fn
              (if (atom rest)
                  rest
                  (else (head rest))))
            (args
              (if (atom rest)
                  ()
                  (else (tail rest))))
            (str "#{rest}"))
        `(if (defined ,fn)
             (,fn ,args)
             (else
                   (print (+ "Didn't know how to handle " ,str " :/\n"))))))))
