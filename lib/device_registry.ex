defmodule ElixirInterviewStarter.DeviceRegistry do
  @moduledoc false
  alias __MODULE__

  def start_link(_) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @spec whereis_name(String.t()) :: :undefined | pid
  def whereis_name(name) do
    Registry.whereis_name({__MODULE__, name})
  end

  @spec via_tuple(String.t()) ::
          {:via, Registry, {DeviceRegistry, String.t()}}
  def via_tuple(name) do
    {:via, Registry, {__MODULE__, name}}
  end
end

