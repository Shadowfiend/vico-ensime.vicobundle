(if (not (defined bundlePath))
  (set bundlePath ("/Users/Shadowfiend/github/vico-ensime.vicobundle")))

(load (+ bundlePath "/ensime-task.nu"))
(load (+ bundlePath "/ensime-processor.nu"))

(function guess-settings-for (directory)
  (function guess-package ()
    ; TODO Obviously fill in some guessing code here, probably look for
    ; TODO (com|net|org|...)/, src/(com|...), src/main/scala/(com|...)
    "com.openstudy")

  (let (use-sbt
          ((NSFileManager defaultManager) fileExistsAtPath:(+ directory "/build.sbt")))
    (if (use-sbt)
        `(:root-dir ,directory
          :use-sbt t)
        (else
              `(:root-dir ,directory
                :package ,(guess-package))))))

(class EnsimeProject is NSObject
  ;(ivar (id) project-config
  ;      (id) ensime-task
  ;      (id) sequence-number
  ;      (id) pending-commands
  ;      (id) state)
  
  ; Returns an EnsimeProject if this is a valid project directory;
  ; otherwise, returns nil.
  (+ ensimeProjectInDirectory:(id)directory is
    (if ((NSFileManager defaultManager) fileExistsAtPath:(+ directory "/src"))
        ((self alloc) initWithDirectory:directory)
        (else
              nil)))

  (- initWithDirectory:(id)directory is
    (super init)

    (let (ensime-config-str (NSString stringWithContentsOfFile:(+ directory "/.ensime") encoding:NSUTF8StringEncoding error:nil))
      (set @project-config
        (if ensime-config-str
            (head (tail (parse ensime-config-str)))
            (else
                  (guess-settings-for directory)))))

    (set @sequence-number 0)
    (set @pending-commands (NSMutableDictionary dictionaryWithCapacity:2))
    (set @ensime-task (EnsimeTask ensimeTask))
    (@ensime-task setDelegate:self)

    (@ensime-task start)

    self)

  (- pendingSequence:(id)sequenceNumber is
    (@pending-commands containsKey:sequenceNumber))

  (- sequenceSeen:(id)sequenceNumber is
    (let (handler (@pending-commands objectForKey:sequenceNumber))
      (@pending-commands removeKey:sequenceNumber)
      handler))

  (- sendCommand:(id)command handler:(id)responseHandler is
    (set @sequence-number (+ @sequence-number 1))
    (let (seq @sequence-number)
      (@ensime-task sendCommand:`(:swank-rpc ,command ,seq))
      (@pending-commands setObject:responseHandler forKey:@sequence-number)))

  (- taskInitialized:(id)task is
    ; start things up
    (self sendCommand:'(swank:connection-info)
              handler:
                (do (*server-info)
                  (self initializeProject))))

  (- initializeProject is
    (let ((project-config @project-config)
          (task self))
      (self sendCommand:`(swank:init-project (,@project-config))
                handler:
                  (do (*info)
                    (print "And it says: #{*args}\n")))))

  (- runCommand:(id)command socket:(id)socket is
    (process command)))
