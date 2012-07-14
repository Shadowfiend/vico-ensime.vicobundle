; vico-ensime is used to interact between ensime and vico.
; Ideal goal: code completion and syntax checking + error display for Scala code.
(import Cocoa)

(class EnsimeSocket is NSObject
  (ivar (id) input-stream
        (id) output-stream
        (id) pending-data
        (id) current-data-write-offset)

  (+ socketForPort:(NSInteger)port is
    ((self alloc) initWithPort:port))

  (- initWithPort:(NSInteger)port is
    (super magic)

    (let ((isr ((NuReference alloc) init))
          (osr ((NuReference alloc) init))
          (host (NSHost hostWithName:"localhost")))
      (NSStream getStreamsToHost:host port:port inputStream:isr outputStream:osr)

      (set @input-stream (isr value))
      (set @output-stream (osr value))

      (@input-stream setDelegate:self)
      (@output-stream setDelegate:self)
      
      (@input-stream scheduleInRunLoop:(NSRunLoop currentRunLoop)
                               forMode:NSDefaultRunLoopMode)
      (@output-stream scheduleInRunLoop:(NSRunLoop currentRunLoop)
                                forMode:NSDefaultRunLoopMode)

      (print "scheduled\n")
      (@input-stream open)
      (@output-stream open)

      (print "opened\n"))
    self)

  (- sendCommandString:(id)commandString is
    (let (commandLength (commandString lengthOfBytesUsingEncoding:NSASCIIStringEncoding))
      (let (lengthHex ((commandLength hexValue) substringFromIndex:2))
        (let (lengthString
                (if (< (lengthHex length) 6)
                    (let (difference (- 6 (lengthHex length)))
                      (("" stringByPaddingToLength:difference
                                        withString:"0"
                                   startingAtIndex:0)
                        stringByAppendingString:lengthHex))
                    (else
                         (lengthHex substringToIndex:6))))
          (let (fullCommandString (+ lengthString commandString))
            (let (dataToSend (fullCommandString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES))
              (let (result (@output-stream writeData:dataToSend))
                (print ("Wrote data; result was #{result}.")))))))))

  (- sendPendingData is
    nil)

  (- closeStreams is
    ('(@input-stream @output-stream) each:(do (stream)
      (print "Closing #{stream}")
      (stream close)
      (stream removeFromRunLoop:(NSRunLoop currentRunLoop)
                        forMode:NSDefaultRunLoopMode)))

    (set @input-stream nil)
    (set @output-stream nil))

  (- (void) stream:(id)stream handleEvent:(int)event is
    (print "Stream received event: #{stream}, #{event}\n")
    (case event
      (NSStreamEventHasBytesAvailable
        (if (== stream @input-stream)
          (print "Reading dat")
          (let (data (@input-stream readData))
            (print "Got dat #{data}")
            (print "Try this: #{(NSString stringWithData:data encoding:NSASCIIStringEncoding)}\n"))))
      (NSStreamEventHasSpaceAvailable
        (if (== stream @output-stream)
          (self sendPendingData)))
      (NSStreamEventErrorOccurred
        (let ((status (stream streamStatus))
              (error (stream streamError)))
          (print "Stream error for #{stream}; status #{status}; error  #{(error code)} #{(error localizedDescription)}\n\n"))))))

(class EnsimeTask is PHBTask
  (ivar (id) temp-file
        (id) socket)

  (- dir is
    (print @temp-file))

  (+ ensimeTask is
    ((self alloc) init))

  (- init is
    (set @socket ())
    (set @temp-file ((NSTemporaryDirectory) stringByAppendingPathComponent:(+ "" (* (NSDate timeIntervalSinceReferenceDate) 1000.0) ".txt")))

    (print @temp-file)

    (let (ensime-path (((current-text) environment) objectForKey:"ENSIME_PATH"))
      (super initWithBufferName:"*ensime-buffer*"
                     launchPath:"bin/server"
                      arguments:(list @temp-file)
               workingDirectory:ensime-path
                  isShellScript:YES))

    self)

  (- ensimeSocket is
    (if (== @socket ())
      (let (error (((NuReference) alloc) init))
        (let (portString (NSString stringWithContentsOfFile:@temp-file encoding:NSASCIIStringEncoding error:error))
          (if (portString)
            (set @socket (EnsimeSocket socketForPort:(portString intValue)))
            #(else (Ni     SLog "error: #{((error value) localizedDescription)}"))
            ))))

    @socket)

  (- startSession is
    (self sendCommand:"(:swank-rpc (swank:connection-info) 1)"))

  (- sendCommand:(id)command is
    (let (commandString (+ "" command))
      ((self ensimeSocket) sendCommandString:command))))

(load "console")
(global console ((NuConsoleWindowController alloc) init))
(console toggleConsole:nil)

(global task (EnsimeTask ensimeTask))
(task start)

(function sendCommand ()
  (task sendCommand:"(:swank-rpc (swank:connection-info) 1)"))
