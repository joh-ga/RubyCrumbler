# Script: Window "About"

require 'glimmer-dsl-libui'

class BasicDrawText
  include Glimmer

  def alternating_color_string(initial: false, &block)
    @index = 0 if initial
    @index += 1
    string {
      if @index.odd?
        color r: 0.5, g: 0, b: 0.25, a: 0.7
      else
        color r: 0, g: 0.5, b: 0, a: 0.7
      end

      block.call + "\n\n"
    }
  end

  def launch
    window('About Ruby Crumbler', 600, 400) {
      margined true

      area {
        on_draw do |area_draw_params|
          text {
            # default arguments for x, y, and width are (0, 0, area_draw_params[:area_width])
            # align :left # default alignment
            default_font family: 'Georgia', size: 13, weight: :medium, italic: :normal, stretch: :normal

            alternating_color_string(initial: true) {
              'Ruby Crumbler Version 0.0.1'
            }

            alternating_color_string {
              'Developed by Laura Bernardy, Nora Dirlam, Jakob Engel, and Johanna Garthe.'
            }
            alternating_color_string {
              'some-email@address.com '
            }
            alternating_color_string {
              'March 31, 2022'
            }
            alternating_color_string {
              'This is an open source project written in Ruby. For more information see on GitHub.'
            }
          }
        end
      }
    }.show
  end
end

BasicDrawText.new.launch
