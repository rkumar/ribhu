#require "ribhu/version"

module Ribhu
  extend self
# i had put this inside module but was unable to access it from bin/ribhu
  ## COPIED FROM CYGNUS
  # will go into rbcurse after i test this out
  #
  # pad version of original popuplist
  # Not used in cygnus, so will require testing if used from elsewhere
  # Is meant to replace the original popuplist soon since the original list
  # and other classes have too much work giong on in repaint.
  # Single selection, selection is with ENTER key, SPACE scrolls
  # @param Array values to be displayed
  # @param Hash configuration settings such as row, col, width, height etc
  # @return int - index in list if selected, nil if C-q pressed
  def padpopuplist list, config={}, &block
    raise ArgumentError, "Nil list received by popuplist" unless list

    max_visible_items = config[:max_visible_items]
    row = config[:row] || 5
    col = config[:col] || 5
    relative_to = config[:relative_to]
    if relative_to
      layout = relative_to.form.window.layout
      row += layout[:top]
      col += layout[:left]
    end
    config.delete :relative_to
    longest = list.max_by(&:length)
    width = config[:width] || longest.size()+2 # borders take 2
    if config[:title]
      width = config[:title].size + 2 if width < config[:title].size
    end
    height = config[:height]
    height ||= [max_visible_items || 10+2, list.length+2].min 
    #layout(1+height, width+4, row, col) 
    layout = { :height => 0+height, :width => 0+width, :top => row, :left => col } 
    window = VER::Window.new(layout)
    form = RubyCurses::Form.new window

    listconfig = config[:listconfig] || {}
    listconfig[:list] = list
    listconfig[:width] = width
    listconfig[:height] = height
    #listconfig[:selection_mode] ||= :single
    listconfig.merge!(config)
    listconfig.delete(:row); 
    listconfig.delete(:col); 
    # trying to pass populists block to listbox
    #lb = RubyCurses::List.new form, listconfig, &block
    lb = RubyCurses::TextPad.new form, listconfig, &block
    #lb = Cygnus::TextPad.new form, :height => height, :width => width, :row => 0, :col => 0 , :title => "A title", :name => "popup"
    lb.text(list)
    #
    #window.bkgd(Ncurses.COLOR_PAIR($reversecolor));
    form.repaint
    Ncurses::Panel.update_panels
    begin
      while((ch = window.getchar()) != 999 )
        case ch
        when ?\C-q.getbyte(0)
          break
        else
          lb.handle_key ch
          form.repaint
          if ch == 13 || ch == 10
            return lb.current_index #if lb.selection_mode != :multiple
          end
          #yield ch if block_given?
        end
      end
    ensure
      window.destroy  
    end
    return nil
  end


  ## 
  # Menu creator which displays a menu and executes methods based on keys.
  # In some cases, we call this and then do a case statement on either key or binding.
  #   Call this with care if you do not intend values to be executed. Maybe that was a bad
  #   idea to club execution with display.
  # @param String title
  # @param hash of keys and methods to call
  # @return key pressed, and binding (if found, and responded)
  #
  def menu title, hash, config={}, &block
    raise ArgumentError, "Nil hash received by menu" unless hash
    list = []
    hash.each_pair { |k, v| list << "   #[fg=yellow, bold] #{k} #[/end]    #[fg=green] #{v} #[/end]" }
    #  s="#[fg=green]hello there#[fg=yellow, bg=black, dim]"
    config[:title] = title
    ch = padpopup list, config, &block
    return unless ch
    if ch.size > 1
      # could be a string due to pressing enter
      # but what if we format into multiple columns
      ch = ch.strip[0]
    end

    binding = hash[ch]
    binding = hash[ch.to_sym] unless binding
    if binding
      if respond_to?(binding, true)
        send(binding)
      end
    end
    return ch, binding
  end

  # pops up a list, taking a single key and returning if it is in range of 33 and 126
  # Called by menu, print_help, show_marks etc
  # You may pass valid chars or ints so it only returns on pressing those.
  #
  # @param Array of lines to print which may be formatted using :tmux format
  # @return character pressed (ch.chr)
  # @return nil if escape or C-q pressed
  #
  def padpopup list, config={}, &block
    max_visible_items = config[:max_visible_items]
    row = config[:row] || 5
    col = config[:col] || 5
    # format options are :ansi :tmux :none
    fmt = config[:format] || :tmux
    config.delete :format
    relative_to = config[:relative_to]
    if relative_to
      layout = relative_to.form.window.layout
      row += layout[:top]
      col += layout[:left]
    end
    config.delete :relative_to
    # still has the formatting in the string so length is wrong.
    #longest = list.max_by(&:length)
    width = config[:width] || 60
    if config[:title]
      width = config[:title].size + 2 if width < config[:title].size
    end
    height = config[:height]
    height ||= [max_visible_items || 25, list.length+2].min 
    #layout(1+height, width+4, row, col) 
    layout = { :height => 0+height, :width => 0+width, :top => row, :left => col } 
    window = VER::Window.new(layout)
    form = RubyCurses::Form.new window

    ## added 2013-03-13 - 18:07 so caller can be more specific on what is to be returned
    valid_keys_int = config.delete :valid_keys_int
    valid_keys_char = config.delete :valid_keys_char

    listconfig = config[:listconfig] || {}
    #listconfig[:list] = list
    listconfig[:width] = width
    listconfig[:height] = height
    #listconfig[:selection_mode] ||= :single
    listconfig.merge!(config)
    listconfig.delete(:row); 
    listconfig.delete(:col); 
    # trying to pass populists block to listbox
    lb = RubyCurses::TextPad.new form, listconfig, &block
    if fmt == :none
      lb.text(list)
    else
      lb.formatted_text(list, fmt)
    end
    #
    #window.bkgd(Ncurses.COLOR_PAIR($reversecolor));
    form.repaint
    Ncurses::Panel.update_panels
    if valid_keys_int.nil? && valid_keys_char.nil?
      # changed 32 to 33 so space can scroll list
      valid_keys_int = (33..126)
    end

    begin
      while((ch = window.getchar()) != 999 )

        # if a char range or array has been sent, check if the key is in it and send back
        # else just stay here
        if valid_keys_char
          if ch > 32 && ch < 127
            chr = ch.chr
            return chr if valid_keys_char.include? chr
          end
        end

        # if the user specified an array or range of ints check against that
        # therwise use the range of 33 .. 126
        return ch.chr if valid_keys_int.include? ch

        case ch
        when ?\C-q.getbyte(0)
          break
        else
          if ch == 13 || ch == 10
            s = lb.current_value.to_s # .strip #if lb.selection_mode != :multiple
            return s
          end
          # close if escape or double escape
          if ch == 27 || ch == 2727
            return nil
          end
          lb.handle_key ch
          form.repaint
        end
      end
    ensure
      window.destroy  
    end
    return nil
  end

  # indexes and returns indexed and colored version of list using alpha as indexes
  # See $IDX and get_shortcut for index details
  # @param Array a list of values to index which will then be displayed using a padpopup
  # @returns Array formatted and indexed list
  def index_this_list list
    alist = []
    list.each_with_index { |v, ix| 
      k = get_shortcut ix
      alist << " #[fg=yellow, bold] #{k.ljust(2)} #[end] #[fg=green]#{v}#[end]" 
      # above gets truncated by columnate and results in errors in colorparsers etc
      #alist << " #{k} #{v}" 
    }
    return alist
  end

  $IDX=('a'..'y').to_a
  $IDX.concat ('za'..'zz').to_a
  $IDX.concat ('Za'..'Zz').to_a
  $IDX.concat ('ZA'..'ZZ').to_a

  # a general function that creates a popup list after indexing the current list,
  # takes a key and returns the value from the list that was selected, or nil if the 
  # value was invalid.
  # Called by show_list (cygnus gem) which is in turn called by several methods.
  #
  def indexed_list title, list, config={}, &block
    raise ArgumentError, "Nil list received by indexed_list" unless list
    $stact = 0
    alist = index_this_list list
    longest = list.max_by(&:length)
    #  s="#[fg=green]hello there#[fg=yellow, bg=black, dim]"
    config[:title] = title
    # if width is greater than size of screen then padfresh will return -1 and nothing will print
    config[:width] = [ longest.size() + 10, FFI::NCurses.COLS - 1 ].min
    config[:row] = config[:col] = 0
    ch = padpopup alist, config, &block
    return unless ch
    if ch.size > 1
      # could be a string due to pressing enter
      # but what if we format into multiple columns
      ch = ch.strip[0]
    end
    # we are checking this AFTER the popup has returned, what window will be used ?
    ch = get_index ch
    return nil unless ch

    return list[ch]
  end
  # print in columns
  # ary - array of data
  # sz  - lines in one column
  # This is the original which did not format or color, but since we cannot truncate unless
  # we have unformatted data i need to mix the functionality into columnate_with_indexing
  # Called by print_help, this is generic and can be used as a common func

  def columnate ary, sz
    buff=Array.new
    return buff if ary.nil? || ary.size == 0

    # ix refers to the index in the complete file list, wherease we only show 60 at a time
    ix=0
    while true
      ## ctr refers to the index in the column
      ctr=0
      while ctr < sz

        f = ary[ix]
        # deleted truncate and pad part since we expect cols to be sized same

        if buff[ctr]
          buff[ctr] += f
        else
          buff[ctr] = f
        end

        ctr+=1
        ix+=1
        break if ix >= ary.size
      end
      break if ix >= ary.size
    end
    return buff
  end
  def pbold text
    #puts "#{BOLD}#{text}#{BOLD_OFF}"
    get_single text, :color_pair => $reversecolor
  end
  def perror text
    ##puts "#{RED}#{text}#{CLEAR}"
    #get_char
    #alert text
    get_single text + "  Press a key...", :color_pair => $errorcolor
  end
  def pause text=" Press a key ..."
    get_single text
    #get_char
  end
  ## return shortcut for an index (offset in file array)
  # use 2 more arrays to make this faster
  #  if z or Z take another key if there are those many in view
  #  Also, display ROWS * COLS so now we are not limited to 60.
  def get_shortcut ix
    return "<" if ix < $stact
    ix -= $stact
    i = $IDX[ix]
    return i if i
    return "->"
  end
  ## returns the integer offset in view (file array based on a-y za-zz and Za - Zz
  # Called when user types a key
  #  should we even ask for a second key if there are not enough rows
  #  What if we want to also trap z with numbers for other purposes
  def get_index key, vsz=999
    i = $IDX.index(key)
    return i+$stact if i
    #sz = $IDX.size
    zch = nil
    if vsz > 25
      if key == "z" || key == "Z"
        #print key
        zch = get_char
        #print zch
        i = $IDX.index("#{key}#{zch}")
        return i+$stact if i
      end
    end
    return nil
  end
  ## I thin we need to make this like the command line one TODO
  def get_char
    w = @window || $window
    c = w.getchar
    case c
    when 13,10
      return "ENTER"
    when 32
      return "SPACE"
    when 127
      return "BACKSPACE"
    when 27
      return "ESCAPE"
    end
    keycode_tos c
    #  if c > 32 && c < 127
    #return c.chr
    #end
    ## use keycode_tos from Utils.
  end
  ##
  # prints a prompt at bottom of screen, takes a character and returns textual representation
  # of character (as per get_char) and not the int that window.getchar returns.
  # It uses a window, so underlying text is not touched.
  #
  def get_single text, config={}
    w = one_line_window
    x = y = 0
    color = config[:color_pair] || $datacolor
    color=Ncurses.COLOR_PAIR(color);
    w.attron(color);
    w.mvprintw(x, y, "%s" % text);
    w.attroff(color);
    w.wrefresh
    Ncurses::Panel.update_panels
    chr = get_char
    w.destroy
    w = nil 
    return chr
  end

  ##
  # identical to get_string but does not show as a popup with buttons, just ENTER
  # This is required if there are multiple inputs required and having several get_strings
  # one after the other seems really odd due to multiple popups
  # Unlike, get_string this does not return a nil if C-c pressed. Either returns a string if 
  # ENTER pressed or a blank if C-c or Double Escape. So only blank to be checked
  # TODO up arrow can access history
  def get_line text, config={}
    begin
      w = one_line_window
      form = RubyCurses::Form.new w
      config[:label] = text
      config[:row] = 0
      config[:col] = 1

      #f = Field.new form, :label => text, :row => 0, :col => 1
      f = Field.new form, config
      form.repaint
      w.wrefresh
      while((ch = w.getchar()) != FFI::NCurses::KEY_F10 )
        break if ch == 13
        if ch == 3 || ch == 27 || ch == 2727
          return ""
        end
        begin
          form.handle_key(ch)
          w.wrefresh
        rescue => err
          $log.debug( err) if err
          $log.debug(err.backtrace.join("\n")) if err
          textdialog ["Error in Messagebox: #{err} ", *err.backtrace], :title => "Exception"
          w.refresh # otherwise the window keeps showing (new FFI-ncurses issue)
          $error_message.value = ""
        ensure
        end
      end # while loop

    ensure
      w.destroy
      w = nil 
    end
    return f.text
  end
  def ask prompt, dt=nil
    return get_line prompt
  end
  ##
  # justify or pad list with spaces so we can columnate, uses longest item to determine size
  # @param list to pad
  # @return list padded with spaces
  def padup_list list
    longest = list.max_by(&:length)
    llen = longest.size
    alist = list.collect { |x|
      x.ljust(llen)
    }
    alist
  end


  # pops up a list, taking a single key and returning if it is in range of 33 and 126
  # This is a specialized method and overrides textpads keys and behavior
  #
  def ri_full_indexed_list list, config={}, &block
    config[:row] ||= 0
    config[:col] ||= 0
    config[:width] ||= FFI::NCurses.COLS - config[:col]
    width = config[:width]
    if config[:title]
      width = config[:title].size + 2 if width < config[:title].size
    end
    height = config[:height]
    #height ||= [max_visible_items || 25, list.length+2].min 
    height ||= FFI::NCurses.LINES - config[:row]
    config[:height] = height
    config[:name] = "fil"
    row = config[:row]
    col = config[:col]
    #layout(1+height, width+4, row, col) 
    layout = { :height => 0+height, :width => 0+width, :top => row, :left => col } 
    window = VER::Window.new(layout)
    form = RubyCurses::Form.new window


    #config[:suppress_border] = true
    lb = RubyCurses::TextPad.new form, config, &block
    grows = lb.rows
    gviscols ||= 3
    pagesize = grows * gviscols
    files = list
    patt = nil
    view = nil
    sta = cursor = 0
    $stact = 0 # to prevent crash
    ignorecase = true

    while true
      break if $quitting
      if patt
        if ignorecase
          view = files.grep(/#{patt}/i)
        else
          view = files.grep(/#{patt}/)
        end
      else 
        view = files
      end
      fl=view.size
      sta = 0 if sta < 0
      cursor = fl -1 if cursor >= fl
      cursor = 0 if cursor < 0
      sta = calc_sta pagesize, cursor
      $log.debug "XXX:   sta is #{sta}, size is #{fl}"
      viewport = view[sta, pagesize]
      fin = sta + viewport.size
      #alist = columnate_with_indexing viewport, grows
      viewport = padup_list viewport
      viewport = index_this_list viewport
      alist = columnate viewport, grows
      lb.formatted_text(alist, :tmux)
      # we need to show the next 1 to n of n for long lists
      #@header.text_right "#{$sta+1} to #{fin} of #{fl}"
      #
      form.repaint
      Ncurses::Panel.update_panels

      begin
        
        ch = window.getchar()

        # if a char range or array has been sent, check if the key is in it and send back
        # else just stay here
        #if ( ( ch >= ?a.ord && ch <= ?z.ord ) || ( ch >= ?A.ord && ch <= ?Z.ord ) )
        if ( ( ch >= ?a.ord && ch <= ?z.ord ) || ( ch == ?Z.ord ) )
         
          chr = ch.chr
          
          chr = get_index chr, viewport.size
          # viewport has indexed data
          #viewport = view[sta, pagesize]
          return view[sta+chr] if chr
          next
        end


        case ch
        when 32, "SPACE", ?\M-n.getbyte(0)
          #next_page
          sta += pagesize
          cursor = sta if cursor < sta
          next
        when ?\M-p.getbyte(0)
          # prev page
          sta -= pagesize
          cursor = sta
          next
        when ?/.getbyte(0)
          # filter data on regex
          patt = get_line "Enter pattern: "
          next
        when ?\C-q.getbyte(0)
          return nil
        else
          # close if escape or double escape or C-c
          if ch == 27 || ch == 2727 || ch == 3
            # this just closes the app ! since my finger remains on Ctrl which is Escape
            return nil
          end
          # lets check our own bindings so textpad doesn't take over
          # Either that or check form's first
          # but this way we can just reuse from cetus
          #retval = c_process_key ch
          #next if retval

          retval = form.handle_key ch #if retval == :UNHANDLED
          next if retval != :UNHANDLED
          $log.debug "XXXX form returned #{retval} for #{ch}"
          #alert "got key before lb.handle #{ch.chr}"
          retval = lb.handle_key ch  if retval.nil? || retval == :UNHANDLED
          #          if retval == :UNHANDLED
          #alert "got key in unhdnalde lb.handle #{ch}, #{retval}"
          $log.debug "XXXX textpad returned #{retval} for #{ch}"
        end

        form.repaint
        #end # while getchar
      end
    end # while true
    return nil
  ensure
    window.destroy 
  end
  ##
  # calculate start of display based on current position
  # This is the value 'sta' should have (starting index)
  # @param int pagesize : number of items on one page
  # @param int cur : current cursor position
  # @return int : position where 'sta' should be
  def calc_sta pagesize, cur
    pages = (cur * 1.001 / pagesize).ceil
    pages -= 1 if pages > 0
    return pages * pagesize
  end

end  # module
include Ribhu
