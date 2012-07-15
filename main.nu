; vico-ensime is used to interact between ensime and vico.
; Ideal goal: code completion and syntax checking + error display for Scala code.
(import Cocoa)

(if (not (defined bundlePath))
  (set bundlePath ("/Users/Shadowfiend/github/vico-ensime.vicobundle")))
(load (+ bundlePath "/ensime-project.nu"))

(load "console")
(global console ((NuConsoleWindowController alloc) init))
(console toggleConsole:nil)

(if (defined project) ((project ensime-task) exit))
(global project (EnsimeProject ensimeProjectInDirectory:"/Users/Shadowfiend/openstudy-v2/"))

;(task sendCommand:'(:swank-rpc (swank:init-project (:package "com.openstudy" :root-dir "/Users/Shadowfiend/openstudy-v2/")) 2))
;(task sendCommand:'(:swank-rpc (swank:typecheck-file "src/main/scala/com/openstudy/model/User.scala") 4))
;(task sendCommand:"(:swank-rpc (swank:connection-info) 1)")
