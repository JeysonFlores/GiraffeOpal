########## MODULE argparse BEGIN
### Copyright 2021 © Calvin Rose

(defn- pad-right
"Pad a string on the right with some spaces."
[str n]
(def len (length str))
(if (>= len n)
  str
  (string str (string/repeat " " (- n len)))))

(defn argparse
```
Parse `(dyn :args)` according to options. If the arguments are incorrect,
will return nil and print usage information.

Each option is a table or struct that specifies a flag or option
for the script. The name of the option should be a string, specified
via `(argparse/argparse \"...\" op1-name {...} op2-name {...} ...)`. A help option
and usage text is automatically generated for you.

The keys in each option table are as follows:

* `:kind` - What kind of option is this? One of `:flag`, `:multi`, `:option`, or
  `:accumulate`. A flag can either be on or off, a multi is a flag that can be provided
  multiple times, each time adding 1 to a returned integer, an option is a key that
  will be set in the returned table, and accumulate means an option can be specified
  0 or more times, each time appending a value to an array.
* `:short` - Single letter for shorthand access.
* `:help` - Help text for the option, explaining what it is.
* `:default` - Default value for the option.
* `:required` - Whether or not an option is required.
* `:short-circuit` - Whether or not to stop parsing and fail if this option is hit.
* `:action` - A function that will be invoked when the option is parsed.

There is also a special option name `:default` that will be invoked on arguments
that do not start with a -- or -. Use this option to collect unnamed
arguments to your script. This is separate from the `:default` key in option specifiers.

After "--", every argument is treated as an unnamed argument.

Once parsed, values are accessible in the returned table by the name
of the option. For example `(result \"verbose\")` will check if the verbose
flag is enabled.
```
[description &keys options]

# Add default help option
(def options (merge
               @{"help" {:kind :flag
                         :short "h"
                         :help "Show this help message."
                         :action :help
                         :short-circuit true}}
               options))

# Create shortcodes
(def shortcodes @{})
(loop [[k v] :pairs options :when (string? k)]
  (if-let [code (v :short)]
    (put shortcodes (code 0) {:name k :handler v})))

# Results table and other things
(def res @{:order @[]})
(def args (dyn :args))
(def arglen (length args))
(var scanning true)
(var bad false)
(var i 1)
(var process-options? true)

# Show usage
(defn usage
  [& msg]
  # Only show usage once.
  (if bad (break))
  (set bad true)
  (set scanning false)
  (unless (empty? msg)
    (print "usage error: " ;msg))
  (def flags @"")
  (def opdoc @"")
  (def reqdoc @"")
  (loop [[name handler] :in (sort (pairs options))]
    (def short (handler :short))
    (when short (buffer/push-string flags short))
    (when (string? name)
      (def kind (handler :kind))
      (def usage-prefix
        (string
          ;(if short [" -" short ", "] ["     "])
          "--" name
          ;(if (or (= :option kind) (= :accumulate kind))
             [" " (or (handler :value-name) "VALUE")
              ;(if-let [d (handler :default)]
                 ["=" d]
                 [])]
             [])))
      (def usage-fragment
        (string
          (pad-right (string usage-prefix " ") 45)
          (if-let [h (handler :help)] h "")
          "\n"))
      (buffer/push-string (if (handler :required) reqdoc opdoc)
                          usage-fragment)))
  (print "usage: " (get args 0) " [option] ... ")
  (print)
  (print description)
  (print)
  (unless (empty? reqdoc)
    (print " Required:")
    (print reqdoc))
  (unless (empty? opdoc)
    (print " Optional:")
    (print opdoc)))

# Handle an option
(defn handle-option
  [name handler]
  (array/push (res :order) name)
  (case (handler :kind)
    :flag (put res name true)
    :multi (do
             (var count (or (get res name) 0))
             (++ count)
             (put res name count))
    :option (if-let [arg (get args i)]
              (do
                (put res name arg)
                (++ i))
              (usage "missing argument for " name))
    :accumulate (if-let [arg (get args i)]
                  (do
                    (def arr (or (get res name) @[]))
                    (array/push arr arg)
                    (++ i)
                    (put res name arr))
                  (usage "missing argument for " name))
    # default
    (usage "unknown option kind: " (handler :kind)))

  # Allow actions to be dispatched while scanning
  (when-let [action (handler :action)]
            (cond
              (= action :help) (usage)
              (function? action) (action)))

  # Early exit for things like help
  (when (handler :short-circuit)
    (set scanning false)))

# Iterate command line arguments and parse them
# into the run table.
(while (and scanning (< i arglen))
  (def arg (get args i))
  (cond
    # `--` turns off option processing so that
    # the rest of arguments are treated like unnamed arguments.
    (and (= "--" arg) process-options?)
    (do
      (set process-options? false)
      (++ i))

    # long name (--name)
    (and (string/has-prefix? "--" arg) process-options?)
    (let [name (string/slice arg 2)
          handler (get options name)]
      (++ i)
      (if handler
        (handle-option name handler)
        (usage "unknown option " name)))

    # short names (-flags)
    (and (string/has-prefix? "-" arg) process-options?)
    (let [flags (string/slice arg 1)]
      (++ i)
      (each flag flags
        (if-let [x (get shortcodes flag)]
          (let [{:name name :handler handler} x]
            (handle-option name handler))
          (usage "unknown flag " arg))))

    # default
    (if-let [handler (options :default)]
      (handle-option :default handler)
      (usage "could not handle option " arg))))

# Handle defaults, required options
(loop [[name handler] :pairs options]
  (when (nil? (res name))
    (when (handler :required)
      (usage "option " name " is required"))
    (put res name (handler :default))))

(if-not bad res))
########## MODULE argparse END

########## MODULE opal BEGIN
### Copyright 2021 © Jeyson Antonio Flores Deras

(defn green-string
  "A function that colors a string to green"
  [str]
  (string "\u001b[32;1m" str "\u001b[0m"))

(defn yellow-string
  "A function that colors a string to green"
  [str]
  (string "\u001b[33;1m" str "\u001b[0m"))

(defn subdir
  "A function that imports the build.janet file from a subdirectory."
  [dir]
  (import* (string "./" dir "/build") :prefix ""))

(defn install-data
  "A function that install a specific file in a specific folder"
  [src-file destdir]
  (os/shell (string "sudo cp " src-file " " destdir)))

(defn define-subdir
  "A function that sets up the working path for the subdirectory."
  [dir]
  (print (string "SUBDIR " (yellow-string dir) " BEGINS"))
  (os/cd dir))

(defn end-subdir
  "A function that goes back to the original working path"
  []
  (print "SUBDIR ENDS")
  (os/cd ".."))

(defn set-build-path
  "A function that sets the build path according to the variable given"
  [args]
  (if (= true (get args "FLATPAK"))
    (os/setenv "BUILD_PATH" "/app/")
    (os/setenv "BUILD_PATH" "/usr/local/")))

(defn get-build-path
  "A function that retrieves the build path"
  []
  (os/getenv "BUILD_PATH"))

(defn set-project
  "A function that takes an array with all the project's information"
  [proj sources]
  (print (green-string (string "----------" (get proj :name) "-Toolchain------")))
  (print (string "Author: " (green-string (get proj :author))))
  (print (string "License: " (green-string (get proj :license))))
  (print (string "Language: " (green-string (get proj :language))))
  (print (string "URL: " (green-string (get proj :url))))
  (print (string "Sources: " (green-string (string "|" (string/join sources "|") "|"))))
  (print (green-string "--------------------")))

########## MODULE opal END