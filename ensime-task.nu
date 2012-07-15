(if (not (defined bundlePath))
  (set bundlePath ("/Users/Shadowfiend/github/vico-ensime.vicobundle")))

(load (+ bundlePath "/ensime-socket.nu"))

(class EnsimeTask is PHBTask
  ;(ivar (id) temp-file
  ;      (id) socket
  ;      (id) delegate
  ;      (id) initialized)

  (+ ensimeTask is
    ((self alloc) init))

   (- init is
     (set @socket ())
     (set @temp-file ((NSTemporaryDirectory) stringByAppendingPathComponent:(+ "" (* (NSDate timeIntervalSinceReferenceDate) 1000.0) ".txt")))
 
     (let (ensime-path (((current-text) environment) objectForKey:"ENSIME_PATH"))
       (super initWithBufferName:"*ensime-buffer*"
                      launchPath:"bin/server"
                       arguments:(list @temp-file)
                workingDirectory:ensime-path
                   isShellScript:YES))
 
     self)

  (- handleOutput:(id)output isError:(BOOL)isError is
    (if (and (not @initialized) (/^Wrote port/ findInString:output))
      (set @initialized t)
      (if ((self delegate) respondsToSelector:"taskInitialized:")
        ((self delegate) taskInitialized:self))))

  (- ensimeSocket is
    (if (not @socket)
      (let (error (((NuReference) alloc) init))
        (let (portString (NSString stringWithContentsOfFile:@temp-file encoding:NSASCIIStringEncoding error:error))
          (if (portString)
            (set @socket (EnsimeSocket socketForPort:(portString intValue)))
            (@socket setDelegate:(self delegate))
            (else (self appendOutput:"Error reading temp file: #{((error value) localizedDescription)}"))))))

    @socket)

  (- setDelegate:(id)delegate is
    (set @delegate delegate)
    (@socket setDelegate:delegate))

  (- sendCommand:(id)command is
    ((self ensimeSocket) sendCommand:command)))
