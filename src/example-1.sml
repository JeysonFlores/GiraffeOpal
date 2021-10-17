fun printHello () = print "Hello World\n"

fun activate app () =
  let
    open Gtk

    val headerbar = HeaderBar.new
    val window = ApplicationWindow.new app
    val () = Window.setDefaultSize window (200, 200)

    val buttonBox = ButtonBox.new Orientation.HORIZONTAL
    val () = Container.add window buttonBox

    val button = Button.newWithLabel "Hello \228\184\150\231\149\140"
    val _ = Signal.connect button (Button.clickedSig, fn () => print "Hello World!\n")
    val () = Container.add buttonBox button

    val () = Widget.showAll window
  in
    ()
  end

fun main () =
  let
    val app = Gtk.Application.new (SOME "com.github.jeysonflores.sml", Gio.ApplicationFlags.FLAGS_NONE)
    val id = Signal.connect app (Gio.Application.activateSig, activate app)

    val argv = Utf8CPtrArrayN.fromList (CommandLine.name () :: CommandLine.arguments ())
    val status = Gio.Application.run app argv

    val () = Signal.disconnect app id
  in
    Giraffe.exit status
  end
    handle e => Giraffe.error 1 ["Uncaught exception\n", exnMessage e, "\n"]
