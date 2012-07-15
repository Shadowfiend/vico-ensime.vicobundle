(class EnsimeSocket is NSObject
  ;(ivar (id) stream
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

    (set @stream (ViBufferedStream streamWithHost:"localhost" port:(port stringValue)))
    (@stream setDelegate:self)

    (@stream schedule)

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
            (set @pending-data (+ @pending-data fullCommandString))
            (@stream writeString:fullCommandString))))))

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
    (@stream close)

    (set @stream nil))

  (- (void)stream:(id)stream handleEvent:(int)event is
    (case event
      (NSStreamEventHasBytesAvailable
        (let (data (stream data))
          (let (string (NSString stringWithData:data encoding:NSASCIIStringEncoding))
            (if (!= string nil)
              (set @pending-commands (+ @pending-commands (NSString stringWithData:data encoding:NSASCIIStringEncoding)))
              (self runNextCommand)))))
      (NSStreamEventHasSpaceAvailable
          (self sendPendingData))
      (NSStreamEventErrorOccurred
        (let ((status (stream streamStatus))
              (error (stream streamError)))
          (print "Stream error for #{stream}; status #{status}; error  #{(error code)} #{(error localizedDescription)}\n\n")))
      (NSStreamEventEndEncountered
        (print "Socket stream ended; closing.\n")
        (stream close)))))
