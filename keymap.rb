require "consumer_key"
require "adns5050"

kbd = Keyboard.new

r0, r1, r2, r3 = 4, 5, 6, 7
c0, c1, c2, c3, c4, c5 = 29, 28, 27, 26, 22, 20

kbd.init_matrix_pins(
  [
    [ [r0,c0], [r0,c1], [r0,c2], [r0,c3], [r0,c4], [r0,c5],          [c5,r0], [c4,r0], [c3,r0], [c2,r0], [c1,r0], [c0,r0] ],
    [ [r1,c0], [r1,c1], [r1,c2], [r1,c3], [r1,c4], [r1,c5],          [c5,r1], [c4,r1], [c3,r1], [c2,r1], [c1,r1], [c0,r1] ],
    [ [r2,c0], [r2,c1], [r2,c2], [r2,c3], [r2,c4], [r2,c5],          [c5,r2], [c4,r2], [c3,r2], [c2,r2], [c1,r2], [c0,r2] ],
    [          [r3,c0], [r3,c1], [r3,c2], [r3,c3], [r3,c5], [r3,c4], [c5,r3], [c3,r3], [c2,r3], [c1,r3], [c0,r3]          ]
  ]
)

kbd.add_layer :default, %i[
  KC_ESCAPE KC_Q    KC_W    KC_E    KC_R      KC_T              KC_Y     KC_U      KC_I     KC_O     KC_P      KC_MINUS
  KC_TAB    KC_A    KC_S    KC_D    KC_F      KC_G              KC_H     KC_J      KC_K     KC_L     KC_SCOLON KC_BSPACE
  KC_LSFT   KC_Z    KC_X    KC_C    KC_V      KC_B              KC_N     KC_M      KC_COMMA KC_DOT   KC_SLASH  KC_RSFT
            RGB_HUD KC_LALT KC_LCTL LOWER_SPC KC_BTN1  KC_MUTE  KC_BTN2  RAISE_ENT IME      KC_RGUI  RGB_HUI
]
kbd.add_layer :raise, %i[
  KC_GRAVE  KC_EXLM KC_AT   KC_HASH KC_DLR    KC_PERC           KC_CIRC  KC_AMPR   KC_ASTER KC_LPRN  KC_RPRN   KC_EQUAL
  KC_TAB    KC_LABK KC_LCBR KC_LBRC KC_LPRN   KC_QUOTE          KC_LEFT  KC_DOWN   KC_UP    KC_RIGHT KC_UNDS   KC_PIPE
  KC_LSFT   KC_RABK KC_RCBR KC_RBRC KC_RPRN   KC_DQUO           KC_TILD  KC_BSLS   KC_COMMA KC_DOT   KC_SLASH  KC_RSFT
            RGB_HUD KC_LALT KC_LCTL LOWER_SPC KC_BTN1  RGB_TOG  KC_BTN2  RAISE_ENT IME      KC_RGUI  RGB_HUI
]
kbd.add_layer :lower, %i[
  KC_ESCAPE KC_1    KC_2    KC_3    KC_4      KC_5              KC_6     KC_7      KC_8     KC_9     KC_0      KC_EQUAL
  KC_TAB    KC_LABK KC_LCBR KC_LBRC KC_LPRN   KC_QUOTE          KC_LEFT  KC_DOWN   KC_UP    KC_RIGHT KC_NO     KC_BSPACE
  KC_LSFT   KC_RABK KC_RCBR KC_RBRC KC_RPRN   KC_DQUO           KC_NO    KC_BTN1   KC_BTN2  KC_NO    KC_NO     KC_COMMA
            RGB_HUD KC_LALT KC_LCTL LOWER_SPC KC_BTN1  ADNS_TOG KC_BTN2  RAISE_ENT IME      KC_RGUI  RGB_HUI
]

kbd.define_composite_key :IME, %i(KC_RSFT KC_RCTL KC_BSPACE)
kbd.define_mode_key :RAISE_ENT, [ :KC_ENTER, :raise, 150, 150 ]
kbd.define_mode_key :LOWER_SPC, [ :KC_SPACE, :lower, 150, 150 ]

# Initialize RGBLED with pin, underglow_size, backlight_size and is_rgbw.
rgb = RGB.new(
  21, # pin number
  10, # size of underglow pixel
  2   # size of backlight pixel
)
rgb.effect = :breath
rgb.hue = 0
rgb.speed = 25
kbd.append rgb

adns5050 = ADNS5050.new(unit: :BITBANG, sck_pin: 23, copi_pin: 8, cipo_pin: 8, cs_pin: 9)
adns5050.reset_chip
kbd.append adns5050.mouse

# Default CPI
# :ADNS_TOG key is a power button
kbd.define_mode_key :ADNS_TOG,  [ Proc.new { adns5050.toggle_power }, nil, 300, nil ]

encoder = RotaryEncoder.new(0, 1)
encoder.clockwise do
  case kbd.layer
  when :default
    kbd.send_key :KC_VOLU
  when :raise
    kbd.send_key :RGB_SPI
  when :lower
    cpi = adns5050.get_cpi + 1
    cpi = 11 if 11 < cpi
    adns5050.set_cpi cpi
  end
end
encoder.counterclockwise do
  case kbd.layer
  when :default
    kbd.send_key :KC_VOLD
  when :raise
    kbd.send_key :RGB_SPD
  when :lower
    cpi = adns5050.get_cpi - 1
    cpi = 1 if cpi < 1
    adns5050.set_cpi cpi
  end
end
kbd.append encoder

kbd.start!


