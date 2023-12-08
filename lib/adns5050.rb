# Library for ADNS-5050 optical sensor
# filepath: /lib/adns5050.rb
require "mouse"
require "spi"

class ADNS5050
  CPI = [ nil, 125, 250, 375, 500, 625, 750, 875, 1000, 1125, 1250, 1375 ]

  def initialize(unit:, sck_pin:, copi_pin:, cipo_pin:, cs_pin:)
    @spi = SPI.new(unit: unit, sck_pin: sck_pin, copi_pin: copi_pin, cipo_pin: cipo_pin, cs_pin: cs_pin)
    @mouse = Mouse.new(driver: @spi)
    @mouse.task do |mouse, keyboard|
      next if @power_down
      y, x = mouse.driver.select do |spi|
        spi.write(0x63) # Motion_Burst
        spi.read(2).bytes
      end
      if 0 < x || 0 < y
        x = 0x7F < x ? (~x & 0xff) + 1 : -x
        y = 0x7F < y ? (~y & 0xff) + 1 : -y
        if keyboard.layer == :lower
          x = 0 < x ? 1 : (x < 0 ? -1 : x)
          y = 0 < y ? 1 : (y < 0 ? -1 : y)
          USB.merge_mouse_report(0, 0, 0, y, -x)
        else
          mod = keyboard.modifier
          if 0 < mod & 0b00100010
            # Shift key pressed -> Horizontal or Vertical only
            x.abs < y.abs ? x = 0 : y = 0
          end
          if 0 < mod & 0b01000100
            # Alt key pressed -> Fix the move amount
            x = 0 < x ? 2 : (x < 0 ? -2 : x)
            y = 0 < y ? 2 : (y < 0 ? -2 : y)
          end
          USB.merge_mouse_report(0, y, x, 0, 0)
        end
      end
    end
  end

  attr_reader :power_down, :mouse

  def get_cpi
    @spi.select do |spi|
      spi.write(0x19)
      spi.read(1).bytes[0] & 0b1111
    end
  end

  def set_cpi(cpi)
    @spi.select do |spi|
      spi.write(0x19 | 0x80, cpi | 0b10000)
    end
    puts "CPI: #{CPI[cpi]}"
  end

  def reset_chip
    @spi.select do |spi|
      spi.write(0x3a | 0x80, 0x5a)
    end
    sleep_ms 10
    set_cpi CPI.index(375)
    puts "ADNS-5050 power UP"
  end

  def toggle_power
    if @power_down
      reset_chip
      @power_down = false
    else
      @spi.select do |spi|
        # power down
        spi.write(0x0d | 0x80, 0b10)
      end
      @power_down = true
      puts "ADNS-5050 power DOWN"
    end
  end

end
