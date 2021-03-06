defmodule Paddington.Apps.Supervisor do
  alias Paddington.Apps.LineApp
  alias Paddington.Midi.Emitter

  use Supervisor

  def start_link(app_names) do
    Supervisor.start_link(__MODULE__, app_names)
  end

  def init(app_names) do
    reset_grid

    app_names
    |> Enum.with_index
    |> Enum.map(&make_app/1)
    |> supervise(strategy: :one_for_one)
  end

  # Private implementation
  ########################

  defp make_app({app_name, index}), do:
    worker(LineApp, [app_name, index], id: "#{app_name}_#{index}")

  defp reset_grid do
    transducer = Application.get_env(:paddington, :transducer)
    :reset |> transducer.to_midi |> Emitter.emit
  end
end
