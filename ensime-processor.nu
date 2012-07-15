(if (not (defined bundlePath))
  (set bundlePath ("/Users/Shadowfiend/github/vico-ensime.vicobundle")))

(load "match")
(load (+ bundlePath "/ensime-status-commands.nu"))

(macro return (handler *body)
  (match *body
    ((:ok ok-form)
      (if (atom ok-form)
          `(,handler ,ok-form)
          (else `(,handler ',@ok-form))))
    ((:abort code error . rest)
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
    ((:incoming-function form)
      (let (str "#{incoming-function} #{form}")
        `(if (defined ,incoming-function)
             (,incoming-function self ,form)
             (else
                   (print (+ "Didn't know how to handle " ,str " :/\n"))))))
    ((:incoming-function . rest)
      (let (str "#{incoming-function} #{rest}")
        `(if (defined ,incoming-function)
             (,incoming-function self ',rest)
             (else
                   (print (+ "Didn't know how to handle " ,str " :/\n"))))))))
