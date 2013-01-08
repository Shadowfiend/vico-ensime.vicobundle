(load "match")

(set ensime-file-data (NSMutableDictionary dictionaryWithCapacity:15))

(function compiler-ready (project args)
  ((current-window) showMessage:"Compiler ready. The magic begins now.")
  ;(project sendCommand:'(swank:typecheck-file "/Users/Shadowfiend/openstudy-v2/src/main/scala/com/openstudy/model/User.scala")
  ;          handler:
  ;            (do (ok)
  ;              (print "On the mofo.\n"))))
  )
(function full-typecheck-finished (project args)
  ((current-window) showMessage:"Completed a first typecheck."))

(function add-scope-component-in-range (document scope-component range)
  (let ((scope (document scopeAtLocation:(head range)))
        (range-end (head (tail range))))
    (scope addScopeComponent:scope-component)
    (scope setAttributes:(NSArray array)) ; recalculate attributes on next display
    (let (scope-end (+ (head (scope range)) (head (tail (scope range)))))
      (if (< scope-end (head (tail range)))
        (add-scope-component-in-range document scope-component (list scope-end range-end))))))

(macro scala-notes (task (:is-full full-compile :notes note-details))
  (note-details each:(do (note)
    (match note
      ((:sev severity :msg message :beg beginning :ed end :ln line :col column :fl file)
        (((current-window) documents) each:
          (do (document)
            (if (== file ((document fileURL) path))
              (add-scope-component-in-range document "invalid" (list beginning end))
              ((document views) each:
                (do (view)
                  (let (layout ((view textView) layoutManager))
                    (layout invalidateDisplayForCharacterRange:(list beginning (- end beginning))))))))))
      ((other . rest)
        (print "Got a note form we didn't expect: #{note}\n")))))
  ())
