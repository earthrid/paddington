defmodule Paddington.Transducer do
  defmodule OutOfBoundsCoordsError, do: defexception [:message]
  defmacro in_bounds(coord) do
    quote do: unquote(coord) >= 0 and unquote(coord) <= 7
  end

  @grid_status 144
  @right_status 144
  @top_status 176

  @top_base_note 104
  @right_notes [8, 24, 40, 56, 72, 88, 104, 120]

  @base_velocity 12
  @press_velocity 127
  @release_velocity 0

  # MIDI => Paddington
  ####################

  # Top row
  def to_coord({@top_status, note, @press_velocity}), do:
    {:top, note - @top_base_note, :pressed}
  def to_coord({@top_status, note, @release_velocity}), do:
    {:top, note - @top_base_note, :released}

  # Right column
  def to_coord({@right_status, note, @press_velocity}) when note in @right_notes, do:
    {:right, (note - 8) / 16, :pressed}
  def to_coord({@right_status, note, @release_velocity}) when note in @right_notes, do:
    {:right, (note - 8) / 16, :released}

  # Grid
  def to_coord({@grid_status, note, @press_velocity}), do:
    {:grid, rem(note, 16), trunc(note/16), :pressed}
  def to_coord({@grid_status, note, @release_velocity}), do:
    {:grid, rem(note, 16), trunc(note/16), :released}

  # Paddington => MIDI
  ####################

  def to_midi(:grid, pos: {x, y}, colors: colors) when in_bounds(x) and in_bounds(y), do:
    {@grid_status, note(x, y), velocity(colors)}

  def to_midi(:grid, pos: {x, y}, colors: _), do:
    raise OutOfBoundsCoordsError, "x and y must be between 0 and 7"

  # Private implementation
  ########################

  defp note(x, y), do: y * 16 + x

  import Keyword, only: [get: 3]
  defp velocity(colors) do
    red   = (colors |> get(:red, :off)   |> brightness)
    green = (colors |> get(:green, :off) |> brightness) * 16
    red + green + @base_velocity
  end

  defp brightness(:off),    do: 0
  defp brightness(:low),    do: 1
  defp brightness(:medium), do: 2
  defp brightness(:high),   do: 3
end
