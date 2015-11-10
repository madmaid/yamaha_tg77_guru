-- utility functions {{{
local function numToBits(num)
    -- number => string
    local bits = {}
    while num > 0 do
        bits[#bits +1] = num % 2
        num = math.floor( (num - bits[#bits]) / 2 )
    end
    return table.concat(bits):reverse()
end

local function increaseToNbits(bits, N)
    -- string, number => string 
    -- ex: increaseToNbits("010", 8) => "00000010"
    if bits:len() < N then
        repeat bits = 0 .. bits until bits:len() == N
    end
    return bits
end

local function bitsToNum(bits_str)
    local reversed_bits = {}
    -- gsub for str to table
    bits_str:reverse():gsub(".", function(ch) table.insert(reversed_bits, ch) end)

    local magnitude = 1
    local num = 0
    for _, place in ipairs(reversed_bits) do
        num = num + (place * magnitude)
        magnitude = magnitude * 2
    end

    return num
end

local function concatArrays(...)
    -- { tbl1, tbl2, ... } => { merged_array }
    local args = {...}
    local new_arr = {}
    for _, arr in ipairs(args) do
        -- merge
        for k, v in ipairs(arr) do
            table.insert(new_arr, v) end end

    return new_arr
end
-- }}}
-- CONSTANTS {{{
local OPERATOR_VALUES = {0x56, 0x46, 0x36, 0x26, 0x16, 0x06}
local ELEMENT_VALUES = {0x00, 0x20, 0x40, 0x60}
--}}}
-- Groups
-- TODO: replace 0x10 -> XG device number
-- Voice Data Common {{{
local voice_data_common_id_top = "voice_data_common_"
local voice_data_common = Group {
    name = "Voice Data Common",
    sysex_message_template = {
        0xf0, 0x43, 0x10, 0x34, 0x02, 0x00, 0x00, "nn", 0x00, "vv", 0xf7
    },
    Parameter {
        id = voice_data_common_id_top .. "element_select_mode",
        name = "Element Select Mode",
        number = 0x00,
        items = {
            "1AFM_mono", "2AFM_mono", "4AFM_mono",
            "1AFM_poly", "2AFM_poly",
            "1AWM_poly", "2AWM_poly", "4AWM_poly",
            "1AFM_1AWM_poly", "2AFM_2AWM_poly",
            "DRUM_SET"
        },
    }
}
-- }}}
-- Normal Voice Element {{{
local normal_voice_elements = {}
for index, element in ipairs(ELEMENT_VALUES) do
    local normal_voice_element_id_top = "normal_voice_element" .. index .. "_"
    normal_voice_elements[index] = Group {
        name = "Normal Voice Element" .. index,
        sysex_message_template = {
            0xf0, 0x43, 0x10, 0x34, 0x03, element, 0x00, "nn", "vv", 0xf7
        },
        Parameter {
            id = normal_voice_element_id_top .. "level",
            name = "Level",
            number = 0x00
        },
        Parameter {
            id = normal_voice_element_id_top .. "detune",
            name = "Detune",
            number = 0x01,
      items = {"-7", "-6" ,"-5", "-4", "-3", "-2", "-1", "0", "1", "2", "3", "4", "5", "6", "7"},
      item_values = {0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81,
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07},
      default_value = 8,
  -- sign magnitude
        },
        Parameter {
            id = normal_voice_element_id_top .. "note_shift",
            name = "Note Shift",
            number = 0x02,
            display_min_value = -64,
            display_max_value = 63,
            default_value = 64,
        },
        Parameter {
            id = normal_voice_element_id_top .. "note_limit_low",
            name = "Note Limit Low",
            number = 0x03,
            default_value = 0
        },
        Parameter {
            id = normal_voice_element_id_top .. "note_limit_high",
            name = "Note Limit High",
            number = 0x04,
            default_value = 127
        },
        Parameter {
            id = normal_voice_element_id_top .. "note_velocity_low",
            name = "Note Velocity Low",
            number = 0x05,
            default_value = 0
        },
        Parameter {
            id = normal_voice_element_id_top .. "note_velocity_high",
            name = "Note Velocity High",
            number = 0x06,
            default_value = 127
        },
    }
end
-- }}}
-- AFM Element Common {{{
local afm_element_common_pitch_egs = {}
local afm_element_common_lfos = {}
local afm_element_common_sub_lfos = {}
for index, element_value in ipairs(ELEMENT_VALUES) do 
    local afm_element_common_id_top = "afm_element" .. index .. "_common_"
    afm_element_common_pitch_egs[index] = Group {
            name = "AFM Element Common" .. index .. " Pitch EG",
            sysex_message_template = {
                0xf0, 0x43, 0x10, 0x34, 0x05, element_value, 0x00, "nn", 0x00, "vv", 0xf7
            },
            Parameter {
                id = afm_element_common_id_top .. "algorithm_number",
                name = "Algorithm",
                number = 0x00,
                max_value = 45,

                value_callback = function(parameter)
                    -- CAUTION
                    if parameter.value <= 44 then
                        return parameter.value
                    else
                        return 0xff     -- free algorithm
                    end
                end
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_key_on_rate_1",
                name = "KEY_ON Rate 1",
                number = 0x01,
                max_value = 63
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_key_on_rate_2",
                name = "KEY_ON Rate 2",
                number = 0x02,
                max_value = 63
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_key_on_rate_3",
                name = "KEY_ON Rate 3",
                number = 0x03,
                max_value = 63
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_key_off_rate_1",
                name = "KEY_OFF Rate 1",
                number = 0x04,
                max_value = 63
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_key_on_level_0",
                name = "KEY_ON Level 0",
                number = 0x05,
                display_min_value = -64,
                display_max_value = 63,
                default_value = 64
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_key_on_level_1",
                name = "KEY_ON Level 1",
                number = 0x06,
                display_min_value = -64,
                display_max_value = 63,
                default_value = 64
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_key_on_level_2",
                name = "KEY_ON Level 2",
                number = 0x07,
                display_min_value = -64,
                display_max_value = 63,
                default_value = 64
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_key_on_level_3",
                name = "KEY_ON Level 3",
                number = 0x08,
                display_min_value = -64,
                display_max_value = 63,
                default_value = 64
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_key_off_level_1",
                name = "KEY_OFF_Level 1",
                number = 0x09,
                display_min_value = -64,
                display_max_value = 63,
                default_value = 64
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_range",
                name = "Range",
                number = 0x0a,
                items = {"8oct", "2oct", "1oct", "1/2oct"}
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_rate_scaling",
                name = "Rate Scaling",
                number = 0x0b,
                man_value = 0,
                max_value = 7
            },
            Parameter {
                id = afm_element_common_id_top .. "pitch_eg_velocity_Switch",
                name = "Velocity Switch",
                number = 0x0b,
                items = {"off", "on"}
            },
        }
        afm_element_common_lfos[index] = Group {
            name = "AFM Element Common" .. index .. " LFO",
            sysex_message_template = {
                0xf0, 0x43, 0x10, 0x34, 0x05, element_value, 0x00, "nn", 0x00, "vv", 0xf7
            },
            Parameter {
                id = afm_element_common_id_top .. "main_lfo_speed",
                name = "Speed",
                number = 0x0d,
                man_value = 0,
                max_value = 99
            },
            Parameter {
                id = afm_element_common_id_top .. "main_lfo_delay_time",
                name = "Delay Time",
                number = 0x0e,
                man_value = 0,
                max_value = 99
            },
            Parameter {
                id = afm_element_common_id_top .. "main_lfo_picth_modulation_depth",
                name = "Pitch Mod Depth",
                number = 0x0f,
            },
            Parameter {
                id = afm_element_common_id_top .. "main_lfo_amplitude_modulation_depth",
                name = "Amp Mod Depth",
                number = 0x10,
            },
            Parameter {
                id = afm_element_common_id_top .. "main_lfo_filter_modulation_depth",
                name = "Filter Mod Depth",
                number = 0x11,
            },
            Parameter {
                id = afm_element_common_id_top .. "main_lfo_wave",
                name = "Wave",
                number = 0x12,
                items = {"triangle", "saw down", "saw up", "square", "sine", "sample & hold"}
            },
            Parameter {
                id = afm_element_common_id_top .. "main_lfo_initial_phase",
                name = "Init Phase",
                number = 0x13,
                man_value = 0,
                max_value = 99
            },
        }
        afm_element_common_sub_lfos[index] = Group {
            name = "AFM Element Common" .. index .. " Sub LFO",
            sysex_message_template = {
                0xf0, 0x43, 0x10, 0x34, 0x05, element_value, 0x00, "nn", 0x00, "vv", 0xf7
            },
            Parameter {
                id = afm_element_common_id_top .. "sub_lfo_wave",
                name = "Wave",
                number = 0x15,
                items = {"triangle", "saw down", "square", "sample & hold"}
            },
            Parameter {
                id = afm_element_common_id_top .. "sub_lfo_speed",
                name = "Speed",
                number = 0x16,
            },
            Parameter {
                id = afm_element_common_id_top .. "sub_lfo_mode",
                name = "Mode",
                number = 0x17,
                items = {"Delay", "Decay"}
            },
            Parameter {
                id = afm_element_common_id_top .. "sub_lfo_time",
                name = "Time",
                number = 0x18,
                man_value = 0,
                max_value = 99
            },
            Parameter {
                id = afm_element_common_id_top .. "sub_lfo_pitch_modulation_depth",
                name = "Pitch Mod Depth",
                number = 0x19,
            },
        }
end

-- }}}
-- AFM Element {{{
local index = 0
-- local afm_elements = {}
local afm_element_eg_keys = {}
local afm_element_senses = {}
local afm_element_miscs = {}

for el_index, element in ipairs(ELEMENT_VALUES) do
    for op_index, operator in ipairs(OPERATOR_VALUES) do
        index = index + 1   -- 1..24
        local afm_element_id_top = "afm_element" .. index .. "_"

        afm_element_eg_keys[index] = Group {
            name = "AFM Element" .. el_index .. " OP".. op_index .. " EG Key",
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, operator, element, 0x00, "nn", 0x00, "vv", 0xf7},
            Parameter {
                    id = afm_element_id_top .. "eg_key_on_rate_1",
                    name = "KEY_ON Rate 1",
                    number = 0x00,
                    min_value = 0,
                    max_value = 63
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_on_rate_2",
                    name = "KEY_ON Rate 2",
                    number = 0x01,
                    min_value = 0,
                    max_value = 63
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_on_rate_3",
                    name = "KEY_ON Rate 3",
                    number = 0x02,
                    min_value = 0,
                    max_value = 63
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_on_rate_4",
                    name = "KEY_ON Rate 4",
                    number = 0x03,
                    min_value = 0,
                    max_value = 63
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_off_rate_1",
                    name = "KEY_OFF Rate 1",
                    number = 0x04,
                    min_value = 0,
                    max_value = 63
                },
                Parameter {
                    id = afm_element_id_top .. "eg_key_off_rate_2",
                    name = "KEY_OFF Rate 2",
                    number = 0x05,
                    min_value = 0,
                    max_value = 63
                },
                Parameter {
                    id = afm_element_id_top .. "eg_key_on_level_0",
                    name = "KEY_ON Level 0",
                    number = 0x0e,
                    min_value = 0,
                    max_value = 63,
                },
                Parameter {
                    id = afm_element_id_top .. "eg_key_on_level_1",
                    name = "KEY_ON Level 1",
                    number = 0x06,
                    min_value = 0,
                    max_value = 63,
                },
                Parameter {
                    id = afm_element_id_top .. "eg_key_on_level_2",
                    name = "KEY_ON Level 2",
                    number = 0x07,
                    min_value = 0,
                    max_value = 63,
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_on_level_3",
                    name = "KEY_ON Level 3",
                    number = 0x08,
                    min_value = 0,
                    max_value = 63,
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_on_level_4",
                    name = "KEY_ON Level 4",
                    number = 0x09, min_value = 0,
                    max_value = 63,
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_off_level_1",
                    name = "KEY_OFF Level 1",
                    number = 0x0a,
                    min_value = 0,
                    max_value = 63,
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_off_level_2",
                    name = "KEY_OFF Level 2",
                    number = 0x0b,
                    min_value = 0,
                    max_value = 63,
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_sustain_loop_point",
                    name = "Sustain Loop P",
                    number = 0x0c,
                    items = {"S1", "S2", "S3", "S4"}
                }, 
                Parameter {
                    id = afm_element_id_top .. "eg_key_key_on_hold_time",
                    name = "KEY_ON Hold TIme",
                    number = 0x0d,
                    min_value = 0,
                    max_value = 63,
                    default_value = 63,
                    callback = function(parameter)
                        --  reversed value ex: 63 => 0, 0 => 63
                        return parameter.max_value - parameter.value
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "eg_rate_scaling",
                    name = "Rate Scaling",
                    number = 0x0f,
                    -- CAUTION: maybe not work 
                    -- TODO:make values sign magnitude
                    items = {"-7", "-6" ,"-5", "-4", "-3", "-2", "-1", "0", "1", "2", "3", "4", "5", "6", "7"},
                    item_values = {0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81,
                            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07},
                    default_value = 8,
                }, 
            }
        afm_element_senses[index] = Group {
            name = "AFM Element" .. el_index .. " OP".. op_index .. " Sens",
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, operator, element, 0x00, "nn", 0x00, "vv", 0xf7},
                Parameter {
                    id = afm_element_id_top .. "amplitude_modulation_sens",
                    name = "Amp Mod Sens",
                    number = 0x10,
                    min_value = 0,
                    max_value = 7
                },
                Parameter {
                    id = afm_element_id_top .. "velocity_sensitivity",
                    name = "Velocity Sens",
                    number = 0x11,
                    sysex_message_template = {0xf0, 0x43, 0x10, 0x34, operator, element, 0x00, "nn", "vv", 0xf7},
                    items = {"-7", "-6" ,"-5", "-4", "-3", "-2", "-1", "0", "1", "2", "3", "4", "5", "6", "7"},
                    item_values = {0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81,
                            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07},
                    default_value = 8,
                }, 
            }
        afm_element_miscs[index] = Group {
            name = "AFM Element" .. el_index .. " OP".. op_index,
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, operator, element, 0x00, "nn", 0x00, "vv", 0xf7},
                Parameter {
                    id = afm_element_id_top .. "oscilator_input0_source",
                    name = "Osc input0 Source",
                    number = 0x13,
                    min_value = 0,
                    max_value = 10,
                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local input1 = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "oscilator_input1_source"].value
                            ), 4)
                        local input0 = increaseToNbits( numToBits(parameter.value), 4 )

                        return bitsToNum( input1 .. input0 )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "oscilator_input1_source",
                    name = "Osc Input1 Source",
                    number = 0x13,
                    min_value = 0,
                    max_value = 10,

                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local input0 = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "oscilator_input0_source"].value
                            ), 4)
                        local input1 = increaseToNbits( numToBits(parameter.value), 4 )

                        return bitsToNum( input1 .. input0 )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "oscilator_output_destination",
                    name = "Osc Output Dest",
                    number = 0x14,
                    min_value = 0,
                    max_value = 3,

                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local accum_input0 = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "out_accumulator_input0_source"].value
                            ), 2)
                        local accum_input1 = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "out_accumulator_input0_source"].value
                            ), 2)
                        local output_dest = increaseToNbits( numToBits(parameter.value), 1)

                        return bitsToNum( accum_input1 .. accum_input0 .. output_dest )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "out_accumulator_input0_source",
                    name = "Out Accum Input0 Src",
                    number = 0x14,
                    min_value = 0,
                    max_value = 2,

                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local output_dest = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "oscilator_output_destination"].value
                            ), 2)
                        local accum_input1 = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "out_accumulator_input1_source"].value
                            ), 1)
                        local accum_input0 = increaseToNbits( numToBits(parameter.value), 2)

                        return bitsToNum( accum_input1 .. accum_input0 .. output_dest )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "out_accumulator_input1_source",
                    name = "Out Accum Input1 Src",
                    number = 0x14,
                    min_value = 0,
                    max_value = 1,

                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local output_dest = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "oscilator_output_destination"].value()
                            ), 2)
                        local accum_input0 = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "out_accumulator_input0_source"].value()
                            ), 2)
                        local accum_input1 = increaseToNbits( numToBits(parameter.value), 1)

                        return bitsToNum( accum_input1 .. accum_input0 .. output_dest )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "oscilator_input0_shift_value",
                    name = "Osc Input0 Shift",
                    number = 0x15,
                    min_value = 0,
                    max_value = 7,
                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local input1 = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "oscilator_input1_shift_value"].value
                            ), 3)
                        local input0 = increaseToNbits( numToBits(parameter.value), 3)

                        return bitsToNum( input0 .. input1 )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "oscilator_input1_shift_value",
                    name = "Osc Input1 Shift",
                    number = 0x15,
                    min_value = 0,
                    max_value = 7,
                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local input0 = increaseToNbits(numToBits(
                            synthdef.parameters[afm_element_id_top .. "oscilator_input0_shift_value"].value
                            ), 3)
                        local input1 = increaseToNbits( numToBits(parameter.value), 3)

                        return bitsToNum( input0 .. input1 )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "output_level_correction",
                    name = "Output Level Correct",
                    number = 0x16,
                    min_value = 0,
                    max_value = 7,
                },
                Parameter {
                    id = afm_element_id_top .. "waveform_of_oscilator",
                    name = "Osc Waveform",
                    number = 0x17,
                    min_value = 0,
                    max_value = 15,
                },
                Parameter {
                    id = afm_element_id_top .. "m_lfo_pitch_modulation_sensitivity",
                    name = "M_LFO Pitch Mod Sens",
                    number = 0x18,
                    min_value = 0,
                    max_value = 7,

                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local pitch_eg_switch = numToBits(
                            synthdef.parameters[afm_element_id_top .. "pitch_eg_switch"].value
                            )
                        local freq_mode = numToBits(
                            synthdef.parameters[afm_element_id_top .. "frequency_mode"].value
                            )
                        local m_lfo_pitch_mod_sens = increaseToNbits( numToBits(parameter.value), 3)

                        return bitsToNum( m_lfo_pitch_mod_sens .. pitch_eg_switch .. freq_mode )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "pitch_eg_switch",
                    name = "Pitch EG Switch",
                    number = 0x18,
                    items = { "off", "on" },
                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local m_lfo_pitch_mod_sens = increaseToNbits( numToBits(
                        synthdef.parameters[afm_element_id_top .. "m_lfo_pitch_modulation_sensitivity"].value
                            ), 3)
                        local pitch_eg_switch = numToBits(
                            synthdef.parameters[afm_element_id_top .. "pitch_eg_switch"].value
                            )
                        local freq_mode = numToBits(parameter.value)

                        return bitsToNum( m_lfo_pitch_mod_sens .. pitch_eg_switch .. freq_mode )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "frequency_mode",
                    name = "Freq Mode",
                    number = 0x18,
                    min_value = 0,
                    max_value = 1,

                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local m_lfo_pitch_mod_sens = increaseToNbits( numToBits(
                        synthdef.parameters[afm_element_id_top .. "m_lfo_pitch_modulation_sensitivity"].value
                            ), 3)
                        local pitch_eg_switch = numToBits(
                            synthdef.parameters[afm_element_id_top .. "pitch_eg_switch"].value
                            )
                        local freq_mode = numToBits(parameter.value)

                        return bitsToNum( m_lfo_pitch_mod_sens .. pitch_eg_switch .. freq_mode )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "initial_phase_set_enable",
                    name = "Init Phase Switch",
                    number = 0x19,
                    items = { "off", "on" },

                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local init_phase = increaseToNbits( numToBits( synthdef.parameters[
                            afm_element_id_top .. "initial_phase_of_oscilator"].value ), 7)
                        local  is_enable = numToBits(parameter.value)

                        return bitsToNum( is_enable .. init_phase )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "initial_phase_of_oscilator",
                    name = "Init Phase of Osc",
                    number = 0x19,

                    value_callback = function (parameter)
                        local synthdef = parameter.synth_definition
                        local is_enable = numToBits(
                            synthdef.parameters[afm_element_id_top .. "initial_phase_set_enable"].value
                            )
                        local init_phase = increaseToNbits( numToBits(parameter.value), 7 )

                        return bitsToNum( is_enable .. init_phase )
                    end
                },
                Parameter {
                    id = afm_element_id_top .. "pitch_detune",
                    name = "Pitch Detune",
                    number = 0x1a,

                    items = {
                            "-15", "-14", "-13", "-12", "-11", "-10", "-9", 
                            "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1", 
                            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                            "10", "11", "12", "13", "14", "15",
                        },
                    item_values = {
                            0x8f, 0x8e, 0x8d, 0x8c, 0x8b, 0x8a, 0x89,
                            0x88, 0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81,
                            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                            0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e,
                        },
                    default_value = 16,
                },
                Parameter {
                    id = afm_element_id_top .. "out_level",
                    name = "Out Level",
                    number = 0x1b
                },
                Parameter {
                    id = afm_element_id_top .. "out_level_scaling_break_point_1",
                    name = "Scaling Break P 1",
                    number = 0x1c
                },
                Parameter {
                    id = afm_element_id_top .. "out_level_scaling_break_point_2",
                    name = "Scaling Break P 2",
                    number = 0x1d
                },
                Parameter {
                    id = afm_element_id_top .. "out_level_scaling_break_point_3",
                    name = "Scaling Break P 3",
                    number = 0x1e
                },
                Parameter {
                    id = afm_element_id_top .. "out_level_scaling_break_point_4",
                    name = "Scaling Break P 4",
                    number = 0x1f
                },
                Parameter {
                    id = afm_element_id_top .. "out_level_offset_break_point_1",
                    name = "Offset Break P 1",
                    number = 0x20,
                    min_value = 0,
                    max_value = 256,
                    default_value = 128
                },
                Parameter {
                    id = afm_element_id_top .. "out_level_offset_break_point_2",
                    name = "Offset Break P 2",
                    number = 0x21,
                    min_value = 0,
                    max_value = 256,
                    default_value = 128
                },
                Parameter {
                    id = afm_element_id_top .. "out_level_offset_break_point_3",
                    name = "Offset Break P 3",
                    number = 0x22,
                    min_value = 0,
                    max_value = 256,
                    default_value = 128
                },
                Parameter {
                    id = afm_element_id_top .. "out_level_offset_break_point_4",
                    name = "Offset Break P 4",
                    number = 0x23,
                    min_value = 0,
                    max_value = 256,
                    default_value = 128
                },
                Parameter {
                    id = afm_element_id_top .. "rate_velocity_switch",
                    name = "Rate Velocity Switch",
                    number = 0x24,
                    items = { "off", "on" }
                },
                Parameter {
                    id = afm_element_id_top .. "frequency_course",
                    name = "Freq Course",
                    number = 0x25,
                },
                Parameter {
                    id = afm_element_id_top .. "frequency_fine",
                    name = "Freq Fine",
                    number = 0x26,
                }
        }
    end
end
-- }}}
-- AWM Elenemt {{{
local awm_elements = {}
local awm_element_pitch_egs = {}
local awm_element_lfos = {}
local awm_element_amp_egs = {}
local awm_element_amp_eg_outs = {}
for index, element in ipairs(ELEMENT_VALUES) do
    local awm_element_id_top = "awm_element" .. index .. "_"

    awm_elements[index] = Group {
        name = "AWM Element " .. index,
        sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                0x00, "nn", 0x00, "vv", 0xf7},

        Parameter {
            id = awm_element_id_top .. "wavesource",
            name = "wavesource",
            number = 0x00,
            max_value = 2,
        },
        Parameter {
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                0x00, "nn", "vv", 0xf7},
            id = awm_element_id_top .. "waveform",
            name = "Waveform",
            number = 0x01,
            max_value = 256, 
        },
        Parameter {
            id = awm_element_id_top .. "frequency_mode",
            name = "Freq Mode",
            number = 0x02,
            items = {"normal", "fixed"}
        },
        Parameter {
            id = awm_element_id_top .. "fixed_mode_note",
            name = "Fixed Mode Note",
            number = 0x03,
        },
        Parameter {
            id = awm_element_id_top .. "frequency_fine",
            name = "Freq Fine",
            number = 0x04,
            display_min_value = -64,
            display_max_value = 63,
            default_value = 64
        },
        Parameter {
            id = awm_element_id_top .. "pitch_modulation_sensitivity",
            name = "Pitch Mod Sens",
            number = 0x05,
            min_value = 0,
            max_value = 7
        },
    }
    awm_element_pitch_egs[index] = Group {
        name = "AWM Element " .. index .. " Pitch EG",
        sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element, 0x00, "nn", 0x00, "vv", 0xf7},

        Parameter {
            id = awm_element_id_top .. "pitch_eg_key_on_rate_1",
            name = "KEY_ON Rate 1",
            number = 0x06,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_key_on_rate_2",
            name = "KEY_ON Rate 2",
            number = 0x07,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_key_on_rate_3",
            name = "KEY_ON Rate 3",
            number = 0x08,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_key_off_rate_1",
            name = "KEY_OFF Rate 1",
            number = 0x09,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_key_on_level_0",
            name = "KEY_ON Level 0",
            number = 0x0a,
            display_min_value = -64,
            display_max_value = 63,
            default_value = 64
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_key_on_level_1",
            name = "KEY_ON Level 1",
            number = 0x0b,
            display_min_value = -64,
            display_max_value = 63,
            default_value = 64
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_key_on_level_2",
            name = "KEY_ON Level 2",
            number = 0x0c,
            display_min_value = -64,
            display_max_value = 63,
            default_value = 64
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_key_on_level_3",
            name = "KEY_ON Level 3",
            number = 0x0d,
            display_min_value = -64,
            display_max_value = 63,
            default_value = 64
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_key_off_level_1",
            name = "KEY_OFF Level 1",
            number = 0x0e,
            display_min_value = -64,
            display_max_value = 63,
            default_value = 64
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_range",
            name = "Range",
            number = 0x0f,
            items = {"2oct", "1oct", "1/2oct"},
            item_values = {1, 2, 3}
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_rate_scaling",
            name = "Rate Scaling",
            number = 0x10,
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                0x00, "nn", "vv", 0xf7},
            -- CAUTION: maybe not work 
            -- TODO:make values sign magnitude

            items = {"-7", "-6" ,"-5", "-4", "-3", "-2", "-1", "0", "1", "2", "3", "4", "5", "6", "7"},
            item_values = {0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81,
                    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07},
            default_value = 8,
            value_callback = function(parameter)
                if parameter.value >= 128 then
                    parameter.sysex_message_template = {
                        0xf0, 0x43, 0x10, 0x34, 0x07, element, 0x00, "nn", "vv", 0xf7
                    }
                else
                    parameter.sysex_message_template = {
                        0xf0, 0x43, 0x10, 0x34, 0x07, element, 0x00, "nn", 0x00, "vv", 0xf7
                    }
                end
            end
        }, 
        Parameter {
            id = awm_element_id_top .. "pitch_eg_velecity_switch",
            name = "Velocity Switch",
            number = 0x11,
            items = {"off", "on"}
        }, 
    }
    awm_element_lfos[index] = Group {
        name = "AWM Element " .. index .. " Multi LFO",
        sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element, 0x00, "nn", 0x00, "vv", 0xf7},
        -- Multi LFO
        Parameter {
            id = awm_element_id_top .. "multi_lfo_speed",
            name = "Speed",
            number = 0x12,
            min_value = 0,
            max_value = 99
        }, 
        Parameter {
            id = awm_element_id_top .. "multi_lfo_delay_time",
            name = "Delay Time",
            number = 0x13,
            min_value = 0,
            max_value = 99
        }, 
        Parameter {
            id = awm_element_id_top .. "multi_lfo_pitch_modulation_depth",
            name = "Pitch Mod Depth",
            number = 0x14,
        }, 
        Parameter {
            id = awm_element_id_top .. "multi_lfo_amplitude_modulation_depth",
            name = "Amp Mod Depth",
            number = 0x15,
        }, 
        Parameter {
            id = awm_element_id_top .. "multi_lfo_filter_modulation_depth",
            name = "Filter Mod Depth",
            number = 0x16,
        }, 
        Parameter {
            id = awm_element_id_top .. "multi_lfo_wave",
            name = "Wave",
            number = 0x17,
            items = {"triangle", "saw down", "saw up", "square", "sine", "sample & hold"}
        }, 
        Parameter {
            id = awm_element_id_top .. "multi_lfo_initial_phase",
            name = "Init Phase",
            number = 0x18,
            min_value = 0,
            max_value = 99
        }, 
    }
    awm_element_amp_egs[index] = Group {
        name = "AWM Element " .. index .. " Amp EG",
        sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element, 0x00, "nn", 0x00, "vv", 0xf7},
        -- Amp EG
        -- TODO: make name better
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_eg_mode",
            name = "Mode",
            number = 0x4f,
            items = {"normal", "hold"}
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_key_on_rate_1",
            name = "KEY_ON Rate 1 Atk/Hold",
            number = 0x50,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_key_on_rate_2",
            name = "KEY_ON Rate 2 Dec",
            number = 0x51,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_key_on_rate_3",
            name = "KEY_ON Rate 3 Sus",
            number = 0x52,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_key_on_rate_4",
            name = "KEY_ON Rate 4 Dec",
            number = 0x53,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_key_off_rate_1",
            name = "KEY_OFF Rate 1 Rel",
            number = 0x54,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_key_on_level_2",
            name = "KEY_ON Level 2 Dec",
            number = 0x55,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_key_on_level_3",
            name = "KEY_ON Level 3 Dec",
            number = 0x56,
            min_value = 0,
            max_value = 63
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_rate_scaling",
            name = "Rate Scaling",
            number = 0x57,
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                    0x00, "nn", "vv", 0xf7},
            -- CAUTION: maybe not work 
            -- TODO:make values sign magnitude
            items = {"-7", "-6" ,"-5", "-4", "-3", "-2", "-1", "0", "1", "2", "3", "4", "5", "6", "7"},
            item_values = {0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81,
                    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07},
            default_value = 8,
        }, 
    }
    awm_element_amp_eg_outs[index] = Group {
        name = "AWM Element " .. index .. " Amp EG Out Level",
        sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element, 0x00, "nn", 0x00, "vv", 0xf7},

        Parameter {
            id = awm_element_id_top .. "amplitude_eg_out_level_scaling_break_point_1",
            name = "Scaling Break P 1",
            number = 0x58,
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_out_level_scaling_break_point_2",
            name = "Scaling Break P 2",
            number = 0x59,
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_out_level_scaling_break_point_3",
            name = "Scaling Break P 3",
            number = 0x5a,
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_out_level_scaling_break_point_4",
            name = "Scaling Break P 4",
            number = 0x5b,
        }, 
        Parameter {
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                0x00, "nn", "vv", 0xf7},
            id = awm_element_id_top .. "amplitude_eg_out_level_scaling_offset_1",
            name = "Scaling Break Offset 1",
            number = 0x5c,
            display_min_value = -128,
            display_max_value = 127,
            min_value = 0,
            max_value = 256,    
            default_value = 128
        },
        Parameter {
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                0x00, "nn", "vv", 0xf7},
            id = awm_element_id_top .. "amplitude_eg_out_level_scaling_offset_2",
            name = "Scaling Break Offset 2",
            number = 0x5d,
            display_min_value = -128,
            display_max_value = 127,
            min_value = 0,
            max_value = 256,    
            default_value = 128
        },
        Parameter {
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                0x00, "nn", "vv", 0xf7},
            id = awm_element_id_top .. "amplitude_eg_out_level_scaling_offset_3",
            name = "Scaling Break Offset 3",
            number = 0x5e,
            display_min_value = -128,
            display_max_value = 127,
            min_value = 0,
            max_value = 256,    
            default_value = 128
        },
        Parameter {
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                0x00, "nn", "vv", 0xf7},
            id = awm_element_id_top .. "amplitude_eg_out_level_scaling_offset_4",
            name = "Scaling Break Offset 4",
            number = 0x5f,
            display_min_value = -128,
            display_max_value = 127,
            min_value = 0,
            max_value = 256,
            default_value = 128
        },
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_velocity_sensitivity",
            name = "Velocity Sens",
            number = 0x60,
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                    0x00, "nn", "vv", 0xf7},
            -- CAUTION: maybe not work 
            -- TODO:make values sign magnitude
            items = {"-7", "-6" ,"-5", "-4", "-3", "-2", "-1", "0", "1", "2", "3", "4", "5", "6", "7"},
            item_values = {0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81,
                    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07},
            default_value = 8
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_attack_rate_velecity_switch",
            name = "Attack Rate Velocity Switch",
            number = 0x61,
            items = {"off", "on"}
        }, 
        Parameter {
            id = awm_element_id_top .. "amplitude_eg_amplitude_modulation_sensitivity",
            name = "Amplitude Mod Sens",
            number = 0x62,
            sysex_message_template = {0xf0, 0x43, 0x10, 0x34, 0x07, element,
                    0x00, "nn", "vv", 0xf7},
            -- CAUTION: maybe not work 
            -- TODO:make values sign magnitude
            items = {"-7", "-6" ,"-5", "-4", "-3", "-2", "-1", "0", "1", "2", "3", "4", "5", "6", "7"},
            item_values = {0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81,
                    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07},
            default_value = 8
        }
    }
end
-- }}}
-- Sections
-- Section Args {{{
local common_section = { voice_data_common }
common_section["name"] = "Common"
local element_sections = {}

local afm_index = 0
local afm_sections_op13 = {}
local afm_sections_op46 = {}
local afm_sections_op13_eg = {}
local afm_sections_op46_eg = {}

for el_index = 1, #ELEMENT_VALUES do     -- 1,4

    afm_sections_op13[el_index] = {}
    afm_sections_op13[el_index]["name"] = "AFM El" .. el_index .. " 1-3"
    afm_sections_op46[el_index] = {}
    afm_sections_op46[el_index]["name"] = "AFM El" .. el_index .. " 4-6"
    ---[[
    afm_sections_op13_eg[el_index] = {}
    afm_sections_op13_eg[el_index]["name"] = "E" .. el_index .. " 13EG"
    afm_sections_op46_eg[el_index] = {}
    afm_sections_op46_eg[el_index]["name"] = "E" .. el_index .. " 46EG"
    --]]

    ---[[
    for op_index = 1, #OPERATOR_VALUES do  -- 1,6 
        --table.insert(common_section, afm_element_eg_keys[afm_index])

        afm_index = afm_index + 1
        if op_index <= 3 then
            table.insert(afm_sections_op13[el_index], afm_element_miscs[afm_index])
            table.insert(afm_sections_op13[el_index], afm_element_senses[afm_index])
            table.insert(afm_sections_op13_eg[el_index], afm_element_eg_keys[afm_index])
        else
            table.insert(afm_sections_op46[el_index], afm_element_miscs[afm_index])
            table.insert(afm_sections_op46[el_index], afm_element_senses[afm_index])
            table.insert(afm_sections_op46_eg[el_index], afm_element_eg_keys[afm_index])
        end
    end --]]

    element_sections[el_index] = {}
    table.insert(element_sections[el_index], normal_voice_elements[el_index])
    table.insert(element_sections[el_index], afm_element_common_pitch_egs[el_index])
    table.insert(element_sections[el_index], afm_element_common_lfos[el_index])
    table.insert(element_sections[el_index], afm_element_common_sub_lfos[el_index])
    table.insert(element_sections[el_index], awm_elements[el_index])
    table.insert(element_sections[el_index], awm_element_pitch_egs[el_index])
    table.insert(element_sections[el_index], awm_element_lfos[el_index])
    table.insert(element_sections[el_index], awm_element_amp_egs[el_index])
    table.insert(element_sections[el_index], awm_element_amp_eg_outs[el_index])
    element_sections[el_index]["name"] = "Elem " .. el_index
end

-- }}}
return SynthDefinition {
    id = "yamaha_tg77",
    name = "Yamaha TG77",
    author = "oshiosalt [https://github.com/oshiosalt]",
    beta = true,
    content_height = 800,

    Section(common_section),

    Section(element_sections[1]),
    Section(element_sections[2]),
    Section(element_sections[3]),
    Section(element_sections[4]),

    Section(afm_sections_op13[1]),
    Section(afm_sections_op46[1]),
    Section(afm_sections_op13[2]),
    Section(afm_sections_op46[2]),
    Section(afm_sections_op13[3]),
    Section(afm_sections_op46[3]),
    Section(afm_sections_op13[4]),
    Section(afm_sections_op46[4]),

    Section(afm_sections_op13_eg[1]),
    Section(afm_sections_op46_eg[1]),
    Section(afm_sections_op13_eg[2]),
    Section(afm_sections_op46_eg[2]),
    Section(afm_sections_op13_eg[3]),
    Section(afm_sections_op46_eg[3]),
    Section(afm_sections_op13_eg[4]),
    Section(afm_sections_op46_eg[4]),
}
