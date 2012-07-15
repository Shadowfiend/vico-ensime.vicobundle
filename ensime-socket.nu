(class EnsimeSocket is NSObject
  ;(ivar (id) input-stream
  ;      (id) output-stream
  ;      (id) pending-data
  ;      (id) pending-commands
  ;      (id) current-data-write-offset
  ;      (id) delegate)

  (+ socketForPort:(NSInteger)port is
    ((self alloc) initWithPort:port))

  (- initWithPort:(NSInteger)port is
    (set @pending-commands "")
    (set @pending-data "")
    (set @current-data-write-offset 0)

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

      (@input-stream open)
      (@output-stream open))
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
            (@output-stream writeData:(fullCommandString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES)))))))

  (- sendCommand:(id)command is
    (let (commandString (/: / replaceWithString:":" inString:(+ "" command)))
      (self sendCommandString:commandString)))

  (- sendPendingData is
    nil)

  (- parseHexFrom:(id)stringWith6Characters is
    (set stringWith6Characters (stringWith6Characters uppercaseString))
    (set number 0)
    (0 upTo:(min 5 (- (stringWith6Characters length) 1)) do:(do (index)
      (let (char (- (stringWith6Characters characterAtIndex:index) '0'))
        (if (< char 16)
          (set number (| number char))
          (else
               (set number (| number (- char (- 'A' '9' 1))))))
        (set number (<< number 4)))))
    (>> number 4))

  (- readNextCommand is
    (if (>= (@pending-commands length) 6)
      (let ((command-length (self parseHexFrom:(@pending-commands substringToIndex:6)))
            (remaining-command (@pending-commands substringFromIndex:6)))
        (if (>= (remaining-command length) command-length)
          (set @pending-commands (remaining-command substringFromIndex:command-length))
          (let (command (remaining-command substringToIndex:command-length))
            ; We head-tail here because parse returns the command
            ; wrapped in a progn, and we want the bare command.
            (head (tail (parse command))))))))

  (- runNextCommand is
    (let (command (self readNextCommand))
      (if (!= command nil)
        (if ((self delegate) respondsToSelector:"runCommand:socket:")
          (try
            ((self delegate) runCommand:command socket:self)
            (catch (exception)
              (let (trace (((exception stackTrace) map:(do (item) "#{(item function)} @ #{(item filename)}:#{(item lineNumber)}")) componentsJoinedByString:"\t\n"))
                (print "Screwed up while handling #{command},\nwe got: #{exception} at\n\t#{trace}\n"))))
          (else (print "Unhandled command #{command}.")))
        (self runNextCommand))))

  (- closeStreams is
    ('(@input-stream @output-stream) each:(do (stream)
      (stream close)
      (stream removeFromRunLoop:(NSRunLoop currentRunLoop)
                        forMode:NSDefaultRunLoopMode)))

    (set @input-stream nil)
    (set @output-stream nil))

  (- (void) stream:(id)stream handleEvent:(int)event is
    (case event
      (NSStreamEventHasBytesAvailable
        (if (== stream @input-stream)
          (let (data (@input-stream readData))
            (let (string (NSString stringWithData:data encoding:NSASCIIStringEncoding))
              (if (!= string nil)
                (set @pending-commands (+ @pending-commands (NSString stringWithData:data encoding:NSASCIIStringEncoding)))
                (self runNextCommand))))))
      (NSStreamEventHasSpaceAvailable
        (if (== stream @output-stream)
          (self sendPendingData)))
      (NSStreamEventErrorOccurred
        (let ((status (stream streamStatus))
              (error (stream streamError)))
          (print "Stream error for #{stream}; status #{status}; error  #{(error code)} #{(error localizedDescription)}\n\n"))))))
