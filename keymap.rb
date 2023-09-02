require "consumer_key"
require "spi"
require "adns5050"
require "mouse"

kbd = Keyboard.new

r0, r1, r2, r3 = 4, 5, 6, 7
c0, c1, c2, c3, c4, c5 = 29, 28, 27, 26, 22, 20

kbd.init_matrix_pins(
  [
    [ [r0, c0], [r0, c1], [r0, c2], [r0, c3], [r0, c4], [r0, c5], [c5, r0], [c4, r0], [c3, r0], [c2, r0], [c1, r0], [c0, r0] ],
    [ [r1, c0], [r1, c1], [r1, c2], [r1, c3], [r1, c4], [r1, c5], [c5, r1], [c4, r1], [c3, r1], [c2, r1], [c1, r1], [c0, r1] ],
    [ [r2, c0], [r2, c1], [r2, c2], [r2, c3], [r2, c4], [r2, c5], [c5, r2], [c4, r2], [c3, r2], [c2, r2], [c1, r2], [c0, r2] ],
    [ [r3, c0], [r3, c1], [r3, c2], [r3, c3],           [r3, c5], [c5, r3],           [c3, r3], [c2, r3], [c1, r3], [c0, r3] ]
  ]
)

kbd.add_layer :default, %i[
  KC_ESCAPE KC_Q    KC_W    KC_E       KC_R      KC_T      KC_Y      KC_U      KC_I     KC_O     KC_P      KC_MINUS
  KC_TAB    KC_A    KC_S    KC_D       KC_F      KC_G      KC_H      KC_J      KC_K     KC_L     KC_SCOLON KC_BSPACE
  KC_LSFT   KC_Z    KC_X    KC_C       KC_V      KC_B      KC_N      KC_M      KC_COMMA KC_DOT   KC_SLASH  KC_RSFT
            RGB_MOD KC_LALT KC_LCTL    LOWER_SPC KC_BTN1   KC_BTN2   RAISE_ENT SPC_CTL  KC_RGUI  RGB_TOG
]

# Initialize RGBLED with pin, underglow_size, backlight_size and is_rgbw.
rgb = RGB.new(
  21, # pin number
  8,  # size of underglow pixel
  2   # size of backlight pixel
)
rgb.effect = :breath
rgb.hue = 0
rgb.speed = 25
kbd.append rgb

enc_a, enc_b = 0, 1
encoder = RotaryEncoder.new(enc_a, enc_b)
encoder.clockwise { kbd.send_key :RGB_SPI }
encoder.counterclockwise { kbd.send_key :RGB_SPD }
kbd.append encoder

mouse = Mouse.new(driver: ADNS5050.new(sclk: 23, sdio: 8, ncs: 9))
ball_move = 0
mouse.task do |mouse, keyboard|
  _prdid, _revid, motion, y, x = mouse.driver.read(5).bytes
  if 0 < motion
    x = -((~x & 0xff) + 1) if 0x7F < x
    y = -((~y & 0xff) + 1) if 0x7F < y
    if keyboard.layer == :lower
      x = 0 < x ? 1 : (x < 0 ? -1 : x)
      y = 0 < y ? 1 : (y < 0 ? -1 : y)
      USB.merge_mouse_report(0, 0, 0, y, -x)
    else
      if ball_move < 50
        ball_move += 7
        if 50 <= ball_move && keyboard.layer == :default
          keyboard.lock_layer :mouse
        end
      end
      if 0 < keyboard.modifier & 0b00100010
        # Shift key pressed -> Horizontal or Vertical only
        x.abs < y.abs ? x = 0 : y = 0
      end
      if 0 < keyboard.modifier & 0b01000100
        # Alt key pressed -> Fix the move amount
        x = 0 < x ? 2 : (x < 0 ? -2 : x)
        y = 0 < y ? 2 : (y < 0 ? -2 : y)
      end
      USB.merge_mouse_report(0, y, x, 0, 0)
    end
  else
    if 0 < ball_move && !mouse.button_pressed?
      ball_move -= 1
      keyboard.unlock_layer if ball_move == 0
    end
  end
end
kbd.append mouse

kbd.start!

