# Ribhu

ri browser using ncurses

Hopes to make your ruby documentation experience faster. This is a two pane application, with
Classes on the left list, and details on the right.
You may press Enter on a class to see its documention. Pressing ENTER over a method in the right will
fetch its details.

You may mark classes with an upper case alphabet (vim style) and access them directly using single-quote.
Several classes have been bookmarked such as Array, String, Hash, File.

Pressing Alt-c and type in any class or method or portion. If `ri` does not return data or returns
choices, a popup will allows selection of choices.

Browser style, one may backspace through earlier results, or use Alt-n and Alt-p  to go back and forth
between previous and next pages viewed.

Please get back to me if there are cases where it's unhelpful in finding the ridocs.

## Installation

    gem install ribhu

## Usage

Ensure you have ri documentation working. On the command line you may do, "ri String". You should get documentation for the String class. If not proceed as follows:

To get ri documentation, you would do 

     rvm docs generate-ri

If you use any gems for development, e.g. highline or rbcurse-core, use the `--ri` flag while installing the gem (this assumes you've switched off ri and rdocs in your .gemrc).

## Gem name

   rib was taken, so i took the next name that came to mind. "ri" browser.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
