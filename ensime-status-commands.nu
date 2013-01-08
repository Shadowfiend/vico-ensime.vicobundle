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

(function drop-scope-component-in-range (document scope-component range)
  (drop-scope-component-in-range-with-count document scope-component range 0))

(function drop-scope-component-in-range-with-count (document scope-component range count)
  (if (< 20 count)
      (if (< (head range) (head (tail range)))
          (let ((scope (document scopeAtLocation:(head range)))
                (range-end (head (tail range))))
            (print "Doing that range #{range}\n")
            (let (scopes ((scope scopes) select:(do (scope) (!= scope scope-component))))
              (scope setScopes:scopes)
              (scope addScopeComponent:scope-component)
              (scope setAttributes:(NSArray array)) ; recalculate attributes on next display
              (let (scope-end (+ (head (scope range)) (head (tail (scope range)))))
                (if (< scope-end (head (tail range)))
                    (add-scope-component-in-range-with-count document scope-component (list scope-end range-end) (+ count 1)))))))
      (else
            (print "Uh-oh, screwed it up :/"))))

(class ScalaNote is NSObject
  ;(ivar (id) severity
  ;      (id) message
  ;      (id) beginning
  ;      (id) end
  ;      (id) line
  ;      (id) column
  ;      (id) file)

  (+ (id)noteForFile:(id)file withSeverity:(id)severity message:(id)message beginning:(id)beginning end:(id)end atLine:(id)line column:(id)column is
  ((self alloc) initForFile:file withSeverity:severity message:message beginning:beginning end:end atLine:line column:column))
  
  (- (id)initForFile:(id)file withSeverity:(id)severity message:(id)message beginning:(id)beginning end:(id)end atLine:(id)line column:(id)column is
    (set @file file)
    (set @severity severity)
    (set @message message)
    (set @beginning beginning)
    (set @end end)
    (set @line line)
    (set @column column)
    
    self)

  (- (id) length is
    (- @beginning @end)))

(function dictionary-for-key (dictionary key)
  (if (not (dictionary objectForKey:key))
    (dictionary setObject:(NSMutableDictionary dictionaryWithCapacity:5) forKey:key))
  (dictionary objectForKey:key))

(macro scala-notes (task (:is-full full-compile :notes note-details))
  (note-details each:(do (note)
    (match note
      ((:sev severity :msg message :beg beginning :ed end :ln line :col column :fl file)
        (let (existing-notes (dictionary-for-key ensime-file-data file))
          (existing-notes addObject:
            (ScalaNote noteForFile:file
                      withSeverity:severity
                           message:message
                         beginning:beginning
                               end:end
                            atLine:line
                            column:column)
                             forKey:"#{line}-#{column}")))
      ((other . rest)
        (print "Got a note form we didn't expect: #{note}\n")))))

  (((current-window) documents) each:
    (do (document)
      (let (notes (ensime-file-data objectForKey:((document fileURL) path)))
        (unless (not notes)
          (notes each:
            (do (note)
              (add-scope-component-in-range document "severity.#{(note severity)}" (list (note beginning) (note end)))
              ((document views) each:
                (do (view)
                  (let (layout ((view textView) layoutManager))
                    (layout invalidateDisplayForCharacterRange:(list (note beginning) (note length))))))))))))
  ())

(macro clear-all-scala-notes (task nothing)
  ; Clear markers.
  (((current-window) documents) each:
    (do (document)
      (let (notes (ensime-file-data objectForKey:((document fileURL) path)))
        (unless (not notes)
          (notes each:
            (do (note)
              (drop-scope-component-in-range document "severity.#{(note severity)}" (list (note beginning) (note end)))
              ((document views) each:
                (do (view)
                  (let (layout ((view textView) layoutManager))
                    (layout invalidateDisplayForCharacterRange:(list (note beginning) (note length))))))))))))

  ; Clear note records.
  (ensime-file-data removeAllObjects)

  ())

(function add-scopes-for (document)
  (let (notes (ensime-file-data objectForKey:((document fileURL) path)))
    (unless (not notes)
      (notes each:
        (do (location note)
          (add-scope-component-in-range document "severity.#{(note severity)}" (list (note beginning) (note end)))
          ((document views) each:
            (do (view)
              (let (layout ((view textView) layoutManager))
                (layout invalidateDisplayForCharacterRange:(list (note beginning) (note length)))))))))))

(function typecheck-document (document)
  (project sendCommand:`(swank:typecheck-file ,((document fileURL) path))
               handler:
                 (do (ok)
                   (print "Request made it through!\n"))))

((ViEventManager defaultManager) on:"didLoadDocument" do:
  (do (document)
    (add-scopes-for document)
    (typecheck-document document)))
((ViEventManager defaultManager) on:"didSaveDocument" do:
  (do (document)
    (add-scopes-for document)
    (typecheck-document document)))

((ViEventManager defaultManager) on:"caretDidMove" do:
  (do (document)
    (let ((notes (ensime-file-data objectForKey:((document fileURL) path)))
          (view (current-view textView)))
      (let (note (notes objectForKey:"#{(view currentLine)}-#{(view currentColumn)}"))
        (if (note)
          ((current-window) showMessage:(note message)))))))
