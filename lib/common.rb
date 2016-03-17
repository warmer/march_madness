# NOTE: second and overtime periods behave the same for now
TIME_STATES ||= [
  {name: :opening,        time_left: 2400 - 300},
  {name: :meat,           time_left: 300},
  {name: :second_crunch,  time_left: 0},
]
DIFF_STATES ||= [
  {name: :trouble,        diff: -7}, # 11+ points behind
  #{name: :small_trouble,  diff: -4},  # 5-10 points behind
  {name: :tiny_down,      diff: -2},   # 3-7 points behind
  {name: :tied,           diff: 3},   # -2-2 is basically tied
  {name: :tiny_up,        diff: 8},   # 1-7 ahead
  #{name: :small_lead,     diff: 11},  # 5-10 points ahead
  {name: :lead,           diff: 999},  # 11+ points ahead
]

def time_state(seconds_left)
  state = TIME_STATES[0]
  TIME_STATES.each do |s|
    if s[:time_left].to_i <= seconds_left.to_i
      state = s
      break
    end
  end
  state[:name]
end

def diff_state(diff)
  state = nil
  DIFF_STATES.each do |s|
    if s[:diff] > diff
      state = s
      break
    end
  end
  state[:name]
end

