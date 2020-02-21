--  Awake             __
--  -Bird            __   __
--                __
--             __
--        __
--        _______________
--        __
--
--
-- 2.2.1 @frederickk
-- 2.2.0 @tehn
-- llllllll.co/t/21022
--
-- top loop plays notes
-- transposed by bottom loop
--
-- (grid optional)
--
-- E1 changes modes:
-- STEP/LOOP/SOUND/OPTION
--
-- K1 held is alt *
--
-- STEP
-- E2/E3 move/change
-- K2 toggle *clear
-- K3 morph *rand
--
-- LOOP
-- E2/E3 loop length
-- K2 reset position
-- K3 jump position
--
-- SOUND
-- K2/K3 selects
-- E2/E3 changes
--
-- OPTION
-- *toggle
-- E2/E3 changes

engine.name = 'Bird'


-- Properties
local hs = include("lib/halfsecond")

local MusicUtil = require "musicutil"
local BeatClock = require "beatclock"
local tu = require "tabutil"

local options = {}
options.OUTPUT = {"audio", "midi", "audio + midi", "crow out 1+2", "crow ii JF"}
options.STEP_LENGTH_NAMES = {"1 bar", "1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16", "1/24", "1/32", "1/48", "1/64"}
options.STEP_LENGTH_DIVIDERS = {1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64}

local g = grid.connect()

local alt = false

local mode = 1
local mode_names = {"STEP", "LOOP", "SOUND", "OPTION"}

-- defaults are now saved in data/awake/awake.pset
local one = {
  pos = 0,
  length = 8,
  start = 1,
  data = {1,0,3,5,6,7,8,7,0,0,0,0,0,0,0,0}
}

local two = {
  pos = 0,
  length = 7,
  start = 1,
  data = {5,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
}

local midi_out_device
local mini_in_device
local midi_out_channel
local midi_root_note_change = false

local scale_names = {}
local notes = {}
local active_notes = {}

local edit_ch = 1
local edit_pos = 1

snd_sel = 1
local snd_names = {"pw", "att", "rel", "fb", "rate", "pan", "delay_pan"}
local snd_params = {"pw", "attack", "release", "delay_feedback", "delay_rate", "pan", "delay_pan"}
local NUM_SND_PARAMS = #snd_params


local clk = BeatClock.new()
-- local clk_midi = midi.connect()
-- clk_midi.event = function(data)
--   print("clk")
--   clk:process_midi(data)
-- end

local notes_off_metro = metro.init()

local set_loop_data = function(which, step, val)
  params:set(which.."_data_"..step, val)
end


-- Local methods
local function all_notes_off()
  if (params:get("output") == 2 or params:get("output") == 3) then
    for _, a in pairs(active_notes) do
      midi_out_device:note_off(a, nil, midi_out_channel)
    end
  end
  active_notes = {}
end

local function random()
  for i = 1,one.length do
    set_loop_data("one", i, math.floor(math.random() * 9))
  end
  for i = 1,two.length do
    set_loop_data("two", i, math.floor(math.random() * 9))
  end
end

local function morph(loop, which)
  for i = 1,loop.length do
    if loop.data[i] > 0 then
      set_loop_data(which, i, util.clamp(loop.data[i] + math.floor(math.random() * 3) - 1, 1, 8))
    end
  end
end

local function step()
  all_notes_off()

  one.pos = one.pos + 1
  if one.pos > one.length then one.pos = 1 end
  two.pos = two.pos + 1
  if two.pos > two.length then two.pos = 1 end

  if one.data[one.pos] > 0 then
    local note_num = notes[one.data[one.pos] + two.data[two.pos]]
    local freq = MusicUtil.note_num_to_freq(note_num)
    -- Trig Probablility
    if math.random(100) <= params:get("probability") then
    -- Audio engine out
      if params:get("output") == 1 or params:get("output") == 3 then
        engine.hz(freq)
      elseif params:get("output") == 4 then
        crow.output[1].volts = (note_num - 60) / 12
        crow.output[2].execute()
      elseif params:get("output") == 5 then
        crow.ii.jf.play_note((note_num - 60) / 12, 5)
      end

      -- MIDI out
      if (params:get("output") == 2 or params:get("output") == 3) then
        midi_out_device:note_on(note_num, 96, midi_out_channel)
        table.insert(active_notes, note_num)

        -- Note off timeout
        if params:get("note_length") < 4 then
          notes_off_metro:start((60 / clk.bpm / clk.steps_per_beat / 4) * params:get("note_length"), 1)
        end
      end
    end
  end

  if params:get("crow_clock") == 2 then
    crow.output[1]:execute()
  end

  if g then
    gridredraw()
  end

  redraw()
end

local function stop()
  all_notes_off()
end


-- Init
function init()
  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
  end

  midi_in_device = midi.connect(1)
  midi_in_device.event = on_midi_event

  midi_out_device = midi.connect(2)
  midi_out_device.event = function() end

  clk.on_step = step
  clk.on_stop = stop
  clk.on_select_internal = function()
    clk:start()
  end
  clk.on_select_external = reset_pattern
  clk:add_clock_params()

  params:set("bpm", 90)

  params:add{
    type = "option",
    id = "crow_clock",
    name = "crow clock out",
    options = {"off", "on"},
    action = function(value)
      if value == 2 then
        crow.output[1].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end}

  notes_off_metro.event = all_notes_off

  params:add{
    type = "option",
    id = "output",
    name = "output",
    options = options.OUTPUT,
    action = function(value)
      all_notes_off()
      if value == 4 then
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      end
    end}

  params:add{
    type = "number",
    id = "midi_out_device",
    name = "midi out device",
    min = 2,
    max = 4,
    default = 1,
    action = function(value)
      midi_out_device = midi.connect(value)
    end}

  params:add{
    type = "number",
    id = "midi_out_channel",
    name = "midi out channel",
    min = 1,
    max = 16,
    default = 1,
    action = function(value)
      all_notes_off()
      midi_out_channel = value
    end}

  params:add_separator()

  params:add{
    type = "option",
    id = "step_length",
    name = "step length",
    options = options.STEP_LENGTH_NAMES,
    default = 8,
    action = function(value)
      clk.ticks_per_step = 96 / options.STEP_LENGTH_DIVIDERS[value]
      clk.steps_per_beat = options.STEP_LENGTH_DIVIDERS[value] / 4
      clk:bpm_change(clk.bpm)
    end}

  params:add{
    type = "option",
    id = "note_length",
    name = "note length",
    options = {"25%", "50%", "75%", "100%"},
    default = 4}

  params:add{
    type = "option",
    id = "scale_mode",
    name = "scale mode",
    options = scale_names,
    default = 5,
    action = function() build_scale() end}

  params:add{
    type = "number",
    id = "root_note",
    name = "root note",
    min = 0,
    max = 127,
    default = 60,
    formatter = function(param)
      return MusicUtil.note_num_to_name(param:get(), true)
    end,
    action = function() build_scale() end}

  params:add{
    type = "number",
    id = "probability",
    name = "probability",
    min = 0,
    max = 100,
    default = 100,}

  params:add_separator()

  cs_AMP = controlspec.new(0, 1, "lin", 0, 0.5, "")
  params:add{
    type = "control",
    id = "amp",
    controlspec = cs_AMP,
    action = function(x) engine.amp(x) end}

  cs_PW = controlspec.new(0, 100, "lin", 0, 50, "%")
  params:add{
    type="control",
    id="pw",
    controlspec = cs_PW,
    action = function(x) engine.pw(x / 100) end}

  cs_ATT = controlspec.new(0.1, 5, "lin", 0, 0.1, "s")
  params:add{
    type="control",
    id="attack",
    controlspec = cs_ATT,
    action = function(x) engine.attack(x) end}

  cs_REL = controlspec.new(0.1, 5, "lin", 0, 1.2, "s")
  params:add{
    type="control",
    id="release",
    controlspec = cs_REL,
    action = function(x) engine.release(x) end}

  -- cs_GAIN = controlspec.new(0, 4, "lin", 0, 1, "")
  -- params:add{
  --   type="control",
  --   id="gain",
  --   controlspec = cs_GAIN,
  --   action = function(x) engine.gain(x) end}

  cs_PAN = controlspec.new(-1, 1, "lin", 0, 0, "")
  params:add{
    type="control",
    id="pan",
    controlspec = cs_PAN,
    action = function(x) engine.pan(x) end}

  crow.input[1].mode("change", 1, 0.05, "rising")
  crow.input[1].change = function(s)
    morph(one, "one")
    morph(two, "two")
  end
  crow.input[2].mode("change", 1, 0.05, "rising")
  crow.input[2].change = random

  -- clk:start()

  hs.init()

  add_pattern_params()
  -- params:default()
  params:read()
  params:bang()
end

function add_pattern_params()
  params:add_separator()

  params:add{
    type = "number",
    id = "one_length",
    name = "<one> length]",
    min = 1,
    max = 16,
    default = one.length,
    action = function(x) one.length = x end}

  params:add{
    type = "number",
    id = "one_start",
    name = "<one> start]",
    min = 1,
    max = 16,
    default = one.start,
    action = function(x) one.start = x end }

  for i = 1,16 do
    params:add{
      type = "number",
      id= ("one_data_"..i),
      name = ("<one> data "..i),
      min = 0,
      max = 8,
      default = one.data[i],
      action = function(x)one.data[i] = x end }
  end

  params:add_separator()

  params:add{
    type = "number",
    id = "two_length",
    name = "<two> length]",
    min = 1,
    max = 16,
    default = two.length,
    action = function(x)two.length = x end}

  params:add{
    type = "number",
    id = "two_start",
    name = "<two> start]",
    min = 1,
    max = 16,
    default = two.start,
    action = function(x)two.start = x end }

  for i = 1,16 do
    params:add{
      type = "number",
      id= "two_data_"..i,
      name = "<two> data "..i,
      min = 0,
      max = 8,
      default = two.data[i],
      action = function(x) two.data[i] = x end }
  end

  params:add_separator()
end


-- Utils
function build_scale()
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 16)
  local num_to_add = 16 - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[16 - num_to_add])
  end
end


-- UI
function redraw()
  screen.clear()
  screen.line_width(1)
  screen.aa(0)

  -- edit point
  if mode == 1 then
    screen.move(26 + edit_pos * 6, edit_ch == 1 and 33 or 63)
    screen.line_rel(4, 0)
    screen.level(15)
    if alt then
      screen.move(0, 30)
      screen.level(1)
      screen.text("prob")
      screen.move(0, 45)
      screen.level(15)
      screen.text(params:get("probability"))
    end
    screen.stroke()
  end

  -- loop lengths
  screen.move(32, 30)
  screen.line_rel(one.length * 6 - 2, 0)
  screen.move(32, 60)
  screen.line_rel(two.length * 6 - 2, 0)
  screen.level(mode == 2 and 6 or 1)
  screen.stroke()

  -- steps
  for i = 1,one.length do
    screen.move(26 + i * 6, 30 - one.data[i] * 3)
    screen.line_rel(4, 0)
    screen.level(i == one.pos and 15 or ((edit_ch == 1 and one.data[i] > 0) and 4 or (mode == 2 and 6 or 1)))
    screen.stroke()
  end

  for i = 1,two.length do
    screen.move(26 + i * 6, 60 - two.data[i] * 3)
    screen.line_rel(4, 0)
    screen.level(i == two.pos and 15 or ((edit_ch == 2 and two.data[i] > 0) and 4 or (mode == 2 and 6 or 1)))
    screen.stroke()
  end

  -- txt
  --[[  screen.level((not alt and not KEY3) and 15 or 4)
  screen.move(0, 10)
  screen.text("bpm:"..params:get("bpm"))
  screen.level(alt and 15 or 4)
  screen.move(0, 20)
  screen.text("sc:"..params:get("scale_mode"))
  screen.level(KEY3 and 15 or 4)
  screen.move(0, 30)
  screen.text("rt:"..MusicUtil.note_num_to_name(params:get("root_note"), true))

  screen.level(4)
  screen.move(0, 60)
  if alt then screen.text("cut/rel")
  elseif KEY3 then screen.text("loop") end
  --]]

  screen.level(4)
  screen.move(0, 10)
  screen.text(mode_names[mode])

  if mode == 3 then
    screen.level(1)
    screen.move(0, 30)
    screen.text(snd_names[snd_sel])
    screen.level(15)
    screen.move(0, 40)
    screen.text(params:string(snd_params[snd_sel]))
    screen.level(1)
    screen.move(0, 50)
    screen.text(snd_names[snd_sel + 1])
    screen.level(15)
    screen.move(0, 60)
    screen.text(params:string(snd_params[snd_sel + 1]))
  elseif mode == 4 then
    screen.level(1)
    screen.move(0, 30)
    screen.text(alt == false and "bpm" or "div")
    screen.level(15)
    screen.move(0, 40)
    screen.text(alt == false and params:get("bpm") or params:string("step_length"))
    screen.level(1)
    screen.move(0, 50)
    screen.text(alt == false and "root" or "scale")
    screen.level(15)
    screen.move(0, 60)
    screen.text(alt == false and params:string("root_note") or params:string("scale_mode"))
  end

  screen.update()
end

function gridredraw()
  local grid_h = g.rows
  g:all(0)
  if edit_ch == 1 or grid_h == 16 then
    for x = 1,16 do
      if one.data[x] > 0 then g:led(x, 9 - one.data[x], 5) end
    end
    if one.pos > 0 and one.data[one.pos] > 0 then
      g:led(one.pos, 9 - one.data[one.pos], 15)
    else
      g:led(one.pos, 1, 3)
    end
  end
  if edit_ch == 2 or grid_h == 16 then
    local y_offset = 0
    if grid_h == 16 then y_offset = 8 end
    for x = 1,16 do
      if two.data[x] > 0 then g:led(x, 9 - two.data[x] + y_offset, 5) end
    end
    if two.pos > 0 and two.data[two.pos] > 0 then
      g:led(two.pos, 9 - two.data[two.pos] + y_offset, 15)
    else
      g:led(two.pos, 1 + y_offset, 3)
    end
  end
  g:refresh()
end


-- Events
function on_midi_event(data)
  clk:process_midi(data)
  -- print(clk.bpm)
  event = midi.to_msg(data)

  -- print("/*------------------*/")
  -- tu.print(event)

  if event.cc then
    -- 0x0x messages for loop value
    if event.cc == 1 then
      midi_loop_data = (event.val / 8) + 1
      if midi_loop_data <= 8 then
        set_loop_data("one", one.pos, midi_loop_data)
      else
        set_loop_data("two", two.pos, midi_loop_data)
      end
    end
    -- 0x1x messages for loop one length
    if event.cc == 2 then
      params:set("one_length", (event.val / 8) + 1)
    end
    -- 0x2x messages for loop two length
    if event.cc == 3 then
      params:set("two_length", (event.val / 8) + 1)
    end
    -- 0x3x messages for step length
    if event.cc == 7 then
      params:set("step_length", (event.val / 8) + 1)
    end
    -- 0x4x messages for root note, followed by noteon event to determine note
    if event.cc == 10 then
      midi_root_note_change = true
    end
    -- 0x5x messages for scale mode
    if event.cc == 11 then
      midi_scale_mode = (event.val / 8) + 1
      if midi_scale_mode <= 13 then
        params:set("scale_mode", midi_scale_mode)
      elseif midi_scale_mode == 14 then
        params:set("scale_mode", 18)
      elseif midi_scale_mode == 15 then
        params:set("scale_mode", 30)
      elseif midi_scale_mode == 16 then
        params:set("scale_mode", 47)
      end
    end
  end

  if event.note then
    if midi_root_note_change then
      params:set("root_note",  event.note + 12)
      midi_root_note_change = false
    end
  end
end

function enc(n, delta)
  if n == 1 then
    mode  =  util.clamp(mode + delta, 1, 4)
  elseif mode == 1 then --step
    if n == 2 then
      if alt then
        params:delta("probability", delta)
      else
        local p = (edit_ch == 1) and one.length or two.length
        edit_pos = util.clamp(edit_pos + delta, 1, p)
      end
    elseif n == 3 then
      if edit_ch == 1 then
        params:delta("one_data_"..edit_pos, delta)
      else
        params:delta("two_data_"..edit_pos, delta)
      end
    end
  elseif mode == 2 then --loop
    if n == 2 then
      params:delta("one_length", delta)
    elseif n == 3 then
      params:delta("two_length", delta)
    end
  elseif mode == 3 then --sound
    if n == 2 then
      params:delta(snd_params[snd_sel], delta)
    elseif n == 3 then
      params:delta(snd_params[snd_sel + 1], delta)
    end
  elseif mode == 4 then --option
    if n == 2 then
      if alt == false then
        params:delta("bpm", delta)
      else
        params:delta("step_length", delta)
      end
    elseif n == 3 then
      if alt == false then
        params:delta("root_note", delta)
      else
        params:delta("scale_mode", delta)
      end
    end
  end
  redraw()
end

function key(n, z)
  if n == 1 then
    alt = z == 1

  elseif mode == 1 then --step
    if n == 2 and z == 1 then
      if not alt == true then
        -- toggle edit
        if edit_ch == 1 then
          edit_ch = 2
          if edit_pos > two.length then edit_pos = two.length end
        else
          edit_ch = 1
          if edit_pos > one.length then edit_pos = one.length end
        end
      else
        -- clear
        for i = 1,one.length do params:set("one_data_"..i, 0) end
        for i = 1,two.length do params:set("two_data_"..i, 0) end

      end
    elseif n == 3 and z == 1 then
      if not alt == true then
        -- morph
        if edit_ch == 1 then morph(one, "one") else morph(two, "two") end
      else
        -- random
        random()
        gridredraw()
      end
    end
  elseif mode == 2 then --loop
    if n == 2 and z == 1 then
      one.pos = 0
      two.pos = 0
      if alt == true then clk:reset() end
    elseif n == 3 and z == 1 then
      one.pos = math.floor(math.random() * one.length)
      two.pos = math.floor(math.random() * two.length)
    end
  elseif mode == 3 then --sound
    if n == 2 and z == 1 then
      snd_sel = util.clamp(snd_sel - 2, 1, NUM_SND_PARAMS - 1)
    elseif n == 3 and z == 1 then
      snd_sel = util.clamp(snd_sel + 2, 1, NUM_SND_PARAMS - 1)
    end
  elseif mode == 4 then --option
    if n == 2 then
    elseif n == 3 then
    end
  end

--[[
      gridredraw()


      if not clk.external then
        if clk.playing then
          clk:stop()
        else
          clk:start()
        end
      end

]]--

  redraw()
end

function g.key(x, y, z)
  local grid_h = g.rows
  if z > 0 then
    if (grid_h == 8 and edit_ch == 1) or (grid_h == 16 and y <= 8) then
      if one.data[x] == 9 - y then
        set_loop_data("one", x, 0)
      else
        set_loop_data("one", x, 9 - y)
      end
    end
    if (grid_h == 8 and edit_ch == 2) or (grid_h == 16 and y > 8) then
      if grid_h == 16 then y = y - 8 end
      if two.data[x] == 9 - y then
        set_loop_data("two", x, 0)
      else
        set_loop_data("two", x, 9 - y)
      end
    end
    gridredraw()
    redraw()
  end
end

function cleanup()
  params:write()
  clk:stop()
end
