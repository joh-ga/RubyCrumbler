require 'glimmer-dsl-libui'

module RubyCrumbler

  class OtherStuff
    # here place the necessary functions for buttons, progress bar, file upload overview
    # connection to pipeline feature functions that are saved in another script
    # we need only two scripts, right? one for the gui and one for the functions
    # i dont know

    def initialize
      super
    end

    def new_window
      # method that opens new window as e.g. in the help menu --> about and documentation
    end
  end


  class CrumblerGUI
    # this class contains the whole GUI
    include Glimmer

    def initialize

    end

    def launch

      ### START of menu bar
      # menu bar number one
      menu('File') {
        menu_item('Load file(s)') {
          on_clicked do
            file = open_file
            puts file unless file.nil?
          end
        }

        menu_item('Load directory') {
          on_clicked do
            file = save_file
            puts file unless file.nil?
          end
        }

        menu_item('Load text from URL') {
          on_clicked do
            file = save_file
            puts file unless file.nil?
          end
        }

        quit_menu_item {
          on_clicked do
            puts 'Goodbye'
          end
        }
      }

      # menu bar number two
      menu('Help') {
        menu_item('About'){
          on_clicked do
            window('About'){
              # link to new window
            }.show
          end
        }

        menu_item('Documentation'){
          on_clicked do
            window('Documentation'){
              # link to new window
            }.show
          end
        }
      }

      ### START of main window
      window('Ruby Crumbler',500, 400) {

        margined true

        on_closing do
          puts 'Bye Bye'
        end

        vertical_box {
          horizontal_box {

            vertical_box {
              group('Pre-Processing') {
                stretchy false

                vertical_box {
                  checkbox('Data cleaning') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Normalization') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  button('Choose all') {
                    stretchy false

                    on_clicked do
                      msg_box('Information', 'You clicked the button')
                    end
                  }

                  button('Reset') {
                    stretchy false

                    on_clicked do
                      msg_box('Information', 'You clicked the button')
                    end
                  }
                }
              }

              group('Natural Language Processing – Tasks') {
                stretchy false

                vertical_box {

                  checkbox('Tokenization') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Stopword removal') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Stemming') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Lemmatization') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Part-of-Speech Tagging') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  checkbox('Named Entity Recognition') {
                    stretchy false

                    on_toggled do |c|
                      checked = c.checked?
                      # link to the respective pipeline feature
                    end
                  }

                  button('Choose all') {
                    stretchy false

                    on_clicked do
                      msg_box('Information', 'You clicked the button')
                    end
                  }

                  button('Reset') {
                    stretchy false

                    on_clicked do
                      msg_box('Information', 'You clicked the button')
                    end
                  }

                }
              }
            }

            vertical_box {
              group('File Upload Overview') {
                stretchy false

                vertical_box {
                  label('Uploaded file(s)') { stretchy false }
                  label('Uploaded file(s) from directory path') { stretchy false }
                  label('Uploaded text of the website: ') { stretchy false }

                }
              }

            }

          }

          horizontal_separator { stretchy false }

          vertical_box {
            group() {
              stretchy false

              vertical_box {
                button('Run') {
                  stretchy false

                  on_clicked do
                    msg_box('Information', 'You clicked the button')
                  end
                }
                button('Cancel') {
                  stretchy false

                  on_clicked do
                    msg_box('Information', 'You clicked the button')
                  end
                }

                label('Status – Progress bar') { stretchy false }
                @progressbar = progress_bar {
                  stretchy false
                }
              }
            }
          }
        }
      }.show
    end
  end
end

RubyCrumbler::CrumblerGUI.new.launch