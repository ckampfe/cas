defmodule Cas.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ets.new(:cas_atom_table, [
      :named_table,
      :set,
      :public,
      read_concurrency: true,
      write_concurrency: :auto
    ])

    children = [
      # Starts a worker by calling: Cas.Worker.start_link(arg)
      # {Cas.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cas.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
