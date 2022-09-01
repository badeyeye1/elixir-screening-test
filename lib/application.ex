defmodule ElixirInterviewStarter.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirInterviewStarter,
      ElixirInterviewStarter.DeviceRegistry
    ]

    opts = [strategy: :one_for_one, name: ElixirInterviewStarter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
